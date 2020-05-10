local select_gui = {}

local gui = require("__flib__.gui")
local util = require("scripts.util")

local edit_gui = require("scripts.gui.edit")

local function attach_highlight_box(gui_data, player_index, area)
  if gui_data.highlight_box then gui_data.highlight_box.destroy() end
  gui_data.highlight_box = game.get_player(player_index).surface.create_entity{
    name = "tl-highlight-box",
    position = area.left_top,
    bounding_box = util.area.expand(area, 0.25),
    render_player_index = player_index,
    player = player_index,
    blink_interval = 30
  }
end

gui.add_handlers{
  select = {
    selection_listbox = {
      on_gui_selection_state_changed = function(e)
        local player_table = global.players[e.player_index]
        local tilegrid_index = player_table.gui.select.tilegrids[e.element.selected_index]
        attach_highlight_box(player_table.gui.select, e.player_index, player_table.tilegrids.registry[tilegrid_index].area)
      end
    },
    back_button = {
      on_gui_click = function(e)
        local player_table = global.players[e.player_index]
        local gui_data = player_table.gui.select
        player_table.flags.selecting_tilegrid = false
        select_gui.destroy(gui_data.elems.window, e.player_index)
        gui_data.highlight_box.destroy()
        player_table.gui.select = nil
      end
    },
    confirm_button = {
      on_gui_click = function(e)
        local player_table = global.players[e.player_index]
        player_table.flags.selecting_tilegrid = false
        local gui_data = player_table.gui.select
        local tilegrid_index = gui_data.tilegrids[gui_data.elems.selection_listbox.selected_index]
        player_table.tilegrids.editing = tilegrid_index
        local tilegrid_data = player_table.tilegrids.registry[tilegrid_index]
        local edit_gui_elems = edit_gui.create(gui_data.elems.window.parent, e.player_index, tilegrid_data.settings, tilegrid_data.hot_corner)
        select_gui.destroy(gui_data.elems.window, e.player_index)
        player_table.gui.edit = {elems=edit_gui_elems, highlight_box=gui_data.highlight_box, last_divisor_value=edit_gui_elems.divisor_textfield.text}
        player_table.gui.select = nil
      end
    }
  }
}

function select_gui.create(parent, player_index)
  return gui.build(parent, {
    {template="window", children={
      {type="label", style="caption_label", caption={"tl-gui.click-on-tilegrid"}, save_as="label"},
      {type="list-box", items={}, handlers="select.selection_listbox", save_as="selection_listbox"},
      {template="vertically_centered_flow", mods={visible=false}, save_as="dialog_flow", children={
        {type="button", style="back_button", caption={"gui.cancel"}, handlers="select.back_button"},
        {template="pushers.horizontal"},
        {type="button", style="confirm_button", caption={"gui.confirm"}, handlers="select.confirm_button"}
      }}
    }}
  })
end

function select_gui.populate_listbox(player_index, tilegrids)
  local player_table = global.players[player_index]
  local gui_data = player_table.gui.select
  local elems = gui_data.elems
  local listbox = elems.selection_listbox
  local registry = player_table.tilegrids.registry
  -- populate listbox
  for _,i in ipairs(tilegrids) do
    local area = registry[i].area
    listbox.add_item(area.width..", "..area.height)
  end
  listbox.selected_index = 1
  -- change element visibility
  listbox.visible = true
  elems.dialog_flow.visible = true
  -- add data to global table
  gui_data.tilegrids = tilegrids
  -- update label caption
  elems.label.caption = {"tl-gui.select-tilegrid"}
  -- attach a highlight box to the first grid on the list
  attach_highlight_box(gui_data, player_index, registry[tilegrids[1]].area)
end

function select_gui.destroy(window, player_index)
  gui.update_filters("select", player_index, nil, "remove")
  window.destroy()
end

return select_gui