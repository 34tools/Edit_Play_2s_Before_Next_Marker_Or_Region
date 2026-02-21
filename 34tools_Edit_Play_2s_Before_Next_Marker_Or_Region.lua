-- 34tools: Play 2s Before Next Marker or Region (34tools)
-- Line: 34tools Edit
-- 34tools — Audio Tools by Alexey Vorobyov (34birds)
-- @version 0.2.1
-- @author Alexey Vorobyov (34birds)
-- @about
--   Part of 34tools (34tools Edit). REAPER Lua script. No js_ReaScriptAPI required.
-- @description 34tools: Play 2s Before Next Marker or Region — seek/play from 2 seconds before the next marker or region start (uses play cursor while playing). Line: 34tools Edit. Version: 0.2.1. License: MIT.
-- @license MIT.

----------------------------------------------------------------------
-- ИДЕЯ / ПОВЕДЕНИЕ
--
-- Скрипт нужен для быстрого "подъезда" к следующей точке монтажа:
--   • Маркер (marker)
--   • Начало региона (region start)
--
-- Логика такая:
--   1) Определяем "текущую позицию" (в секундах):
--        - Если транспорт активен (Play / Pause / Record) — берём PLAY CURSOR.
--        - Если транспорт не активен — берём EDIT CURSOR.
--   2) Ищем ближайший следующий объект правее текущей позиции:
--        - либо маркер,
--        - либо СТАРТ региона.
--   3) Считаем точку старта: (позиция объекта - PRE_ROLL_SEC).
--        - Не уходим левее 0 сек.
--   4) Если транспорт активен — "перескакиваем" (seek) БЕЗ остановки.
--      Если не активен — ставим курсор и запускаем Play.
--
-- Важно:
--   • Скрипт НЕ учитывает конец региона (rgnend), только старт.
--   • "Следующий" объект должен быть строго правее позиции (с допуском EPS).
----------------------------------------------------------------------

----------------------------------------------------------------------
-- НАСТРОЙКИ
----------------------------------------------------------------------

-- Преролл (в секундах): старт воспроизведения за N секунд до маркера/региона
local PRE_ROLL_SEC = 2.0

-- Микро-допуск, чтобы не ловить объект "на той же позиции" из-за численной погрешности
local EPS = 1e-9

----------------------------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
----------------------------------------------------------------------

-- Показываем короткое системное сообщение (на случай, если "следующего" не найдено)
local function msg(s)
  reaper.ShowMessageBox(tostring(s), "Play 2s Before Next Marker/Region", 0)
end

-- Проверяем, активен ли транспорт.
-- reaper.GetPlayState() возвращает битовую маску, но на практике часто встречаются
-- базовые значения:
--   0 = stopped
--   1 = playing
--   2 = paused
--   5 = recording (1 + 4)
--
-- Нам важно считать "активным" всё, где реально есть play cursor, который можно seek'нуть:
--   play / pause / record.
local function is_transport_active(play_state)
  return (play_state == 1) or (play_state == 2) or (play_state == 5)
end

-- Находим ближайший следующий маркер или старт региона правее cur_pos.
--
-- Возвращает:
--   best_pos  (number|nil)  - позиция (сек) ближайшего объекта
--   best_kind (string|nil)  - "marker" или "region"
--   best_name (string)      - имя объекта (может быть пустым)
local function find_next_marker_or_region_start(cur_pos)
  -- CountProjectMarkers(0) возвращает:
  --   retval, num_markers, num_regions
  local _, num_markers, num_regions = reaper.CountProjectMarkers(0)

  -- EnumProjectMarkers() перечисляет маркеры и регионы в одном общем списке.
  -- Поэтому total = markers + regions.
  local total = (num_markers or 0) + (num_regions or 0)

  local best_pos = nil
  local best_kind = nil
  local best_name = ""

  -- Перебираем все маркеры/регионы проекта
  for i = 0, total - 1 do
    -- EnumProjectMarkers(i):
    --   retval, isrgn, pos, rgnend, name, markrgnindexnumber
    local retval, isrgn, pos, rgnend, name = reaper.EnumProjectMarkers(i)

    if retval then
      -- Для региона нас интересует СТАРТ (pos), а не конец (rgnend)
      local candidate_pos = pos

      -- "Следующий" = строго правее текущей позиции (+ EPS)
      if candidate_pos > (cur_pos + EPS) then
        -- Берём самый ближайший справа (минимальная candidate_pos среди подходящих)
        if (best_pos == nil) or (candidate_pos < best_pos) then
          best_pos = candidate_pos
          best_kind = (isrgn and "region") or "marker"
          best_name = name or ""
        end
      end
    end
  end

  return best_pos, best_kind, best_name
end

----------------------------------------------------------------------
-- ОСНОВНОЙ ВХОД
----------------------------------------------------------------------

reaper.Undo_BeginBlock()

-- Текущее состояние транспорта
local play_state = reaper.GetPlayState()
local transport_active = is_transport_active(play_state)

-- 1) Берём "текущую позицию" в зависимости от транспорта:
--    - если играет/пауза/запись: play cursor
--    - иначе: edit cursor
local cur_pos
if transport_active then
  cur_pos = reaper.GetPlayPosition()
else
  cur_pos = reaper.GetCursorPosition()
end

-- 2) Ищем следующий маркер или старт региона
local next_pos, kind, name = find_next_marker_or_region_start(cur_pos)

-- Если ничего не нашли — показываем сообщение и выходим
if not next_pos then
  reaper.Undo_EndBlock("34tools: Play 2s Before Next Marker/Region (no next found)", -1)
  msg("Не найден следующий маркер или начало региона правее текущей позиции.")
  return
end

-- 3) Считаем стартовую позицию (с прероллом)
local start_pos = next_pos - PRE_ROLL_SEC
if start_pos < 0 then start_pos = 0 end

-- 4) Действуем по ситуации:
--    A) Транспорт активен:
--       Используем seekplay=true через SetEditCurPos — это делает "перескок" без стопа.
--       Важно: moveview=true, чтобы окно таймлайна прыгнуло к новой позиции (удобно).
--    B) Транспорт не активен:
--       Ставим edit cursor и запускаем Play.
if transport_active then
  reaper.SetEditCurPos(start_pos, true, true) -- moveview=true, seekplay=true
else
  reaper.SetEditCurPos(start_pos, true, false) -- moveview=true, seekplay=false
  reaper.Main_OnCommand(1007, 0) -- Transport: Play
end

reaper.Undo_EndBlock("34tools: Play 2s Before Next Marker/Region", -1)
