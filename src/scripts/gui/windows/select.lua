-- ----------------------------------------------------------------------------------------------------
-- SELECT GUI
-- Select which tilegrid to edit

local event = require('scripts/lib/event-handler')
local mod_gui = require('mod-gui')
local util = require('scripts/lib/util')

local edit_gui = require('scripts/gui/windows/edit')
local titlebar = require('scripts/gui/elements/titlebar')

local select_gui = {}

-- --------------------------------------------------
-- LOCAL UTILITIES

local function attach_highlight_box(gui_data, grid_index, player_index)
    local area = global.tilegrids.registry[gui_data.tilegrids[grid_index]].area
    if gui_data.highlight_box then gui_data.highlight_box.destroy() end
    gui_data.highlight_box = util.get_player(player_index).surface.create_entity{
        name = 'highlight-box',
        position = area.left_top,
        bounding_box = util.expand_area(area, 0.25),
        render_player_index = player_index,
        player = player_index,
        blink_interval = 30
    }
end

-- --------------------------------------------------
-- EVENT HANDLERS

local function selection_listbox_state_changed(e)
    attach_highlight_box(util.player_table(e.player_index).gui.select, e.element.selected_index, e.player_index)
end

local function back_button_clicked(e)
    util.debug_print(e)
end

local function confirm_button_clicked(e)
    local player_table = util.player_table(e.player_index)
    player_table.cur_selecting = false
    local select_gui_data = player_table.gui.select
    local tilegrid_index = select_gui_data.tilegrids[select_gui_data.elems.selection_listbox.selected_index]
    player_table.cur_editing = tilegrid_index
    edit_gui.create(select_gui_data.elems.window.parent, e.player_index, global.tilegrids.registry[tilegrid_index].settings)
    select_gui.destroy(select_gui_data.elems.window, e.player_index)
    player_table.gui.select = nil
end

local handlers = {
    select_close_button_clicked = close_button_clicked,
    select_back_button_clicked = back_button_clicked,
    select_confirm_button_clicked = confirm_button_clicked
}

event.on_load(function()
	event.load_conditional_handlers(handlers)
end)

-- --------------------------------------------------
-- LIBRARY

function select_gui.create(parent, player_index)
    local window = parent.add{type='frame', name='tl_select_window', style=mod_gui.frame_style, direction='vertical'}
    window.style.width = 252
    local hint_flow = window.add{type='flow', name='tl_select_hint_flow', style='horizontally_centered_flow', direction='vertical'}
    local hint_label = hint_flow.add{type='label', name='tl_select_hint', style='caption_label', caption={'gui-select.hint-label-caption'}}
    local selection_listbox = window.add{type='list-box', name='tl_select_listbox', items={}}
    selection_listbox.visible = false
    event.gui.on_selection_state_changed(selection_listbox, selection_listbox_state_changed, 'select_selection_listbox_state_changed', player_index)
    local dialog_flow = window.add{type='flow', name='tl_select_dialog_flow', style='dialog_buttons_horizontal_flow', direction='horizontal'}
    local back_button = dialog_flow.add{type='button', name='tl_select_back_button', style='back_button', caption={'gui.cancel'}}
    event.gui.on_click(back_button, back_button_clicked, 'select_back_button_clicked', player_index)
    local confirm_button = dialog_flow.add{type='button', name='tl_select_confirm_button', style='confirm_button', caption={'gui.confirm'}}
    event.gui.on_click(confirm_button, confirm_button_clicked, 'select_confirm_button_clicked', player_index)
    dialog_flow.visible = false
    return {window=window, hint_label=hint_label, selection_listbox=selection_listbox, dialog_flow=dialog_flow, back_button=back_button,
            confirm_button=confirm_button}
end

function select_gui.populate_listbox(player_index, tilegrids)
    local player_table = util.player_table(player_index)
    local gui_data = player_table.gui.select
    local elems = gui_data.elems
    local listbox = elems.selection_listbox
    local registry = global.tilegrids.registry
    -- populate listbox
    for _,i in ipairs(tilegrids) do
        local area = registry[i].area
        listbox.add_item(area.width..', '..area.height)
    end
    listbox.selected_index = 1
    -- change element visibility
    listbox.visible = true
    elems.dialog_flow.visible = true
    -- add data to global table
    gui_data.highlight_box = highlight_box
    gui_data.tilegrids = tilegrids
    -- attach a highlight box to the first grid on the list
    attach_highlight_box(gui_data, 1, player_index)
end

function select_gui.destroy(window, player_index)
    -- deregister all GUI events if needed
    local con_registry = global.conditional_event_registry
    for cn,h in pairs(handlers) do
        event.gui.deregister(con_registry[cn].id, h, cn, player_index)
    end
	window.destroy()
end

return select_gui