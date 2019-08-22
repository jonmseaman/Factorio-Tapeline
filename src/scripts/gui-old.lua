local event = require('__stdlib__/stdlib/event/event')
local on_event = event.register
local gui = require('__stdlib__/stdlib/event/gui')

local lib = {}

-- ------------------------------------------------------------
-- SETTINGS MENU

-- create a menu for the player
local function create_settings_menu(player, mod_gui)
    local menu_frame = mod_gui.add{type='frame', name='tapeline_menu_frame', style=mod_gui.frame_style, direction='vertical'}

    -- HEADER
    local header_flow = menu_frame.add{type='flow', name='header_flow', direction='horizontal'}
    header_flow.style.horizontally_stretchable = true
    header_flow.style.bottom_margin = 2
    header_flow.add{type='label', name='menu_title', style='heading_1_label', caption={'gui-caption.settings-header-caption', global.player_data[player.index].cur_tilegrid_index}}
    header_flow.add{type='flow', name='header_spacer', direction='horizontal'}
    header_flow.header_spacer.style.horizontally_stretchable = true
    header_flow.add{type='sprite-button', name='confirm_button', style='green_icon_button', sprite='check_mark', tooltip={'gui-tooltip.confirm-tooltip'}}
    header_flow.add{type='sprite-button', name='delete_button', style='red_icon_button', sprite='utility/trash', tooltip={'gui-tooltip.delete-tooltip'}}

    -- CHECKBOXES
    local checkboxes_flow = menu_frame.add{type='flow', name='checkboxes_flow', direction='horizontal'}
    -- auto clear
    checkboxes_flow.add{type='checkbox', name='autoclear_checkbox', style='caption_checkbox', state=true, caption={'gui-caption.autoclear-caption'}, tooltip={'gui-tooltip.autoclear-tooltip', settings.global['tilegrid-clear-delay'].value}}
    -- spacer
    checkboxes_flow.add{type='flow', name='checkboxes_spacer', direction='horizontal'}
    checkboxes_flow.checkboxes_spacer.style.horizontally_stretchable = true
    -- restrict to cardinals
    checkboxes_flow.add{type='checkbox', name='restrict_to_cardinals_checkbox', style='caption_checkbox', state=false, caption={'gui-caption.restrict-to-cardinals-caption'}, tooltip={'gui-tooltip.restrict-to-cardinals-tooltip'}}

    -- GRID TYPE
    local gridtype_flow = menu_frame.add{type='flow', name='gridtype_flow', direction='horizontal'}
    gridtype_flow.add{type='label', name='gridtype_label', style='caption_label', caption={'gui-caption.gridtype-caption'}}
    gridtype_flow.add{type='flow', name='gridtype_spacer', direction='horizontal'}
    gridtype_flow.gridtype_spacer.style.horizontally_stretchable = true
    gridtype_flow.style.vertical_align = 'center'
    gridtype_flow.add{type='drop-down', name='gridtype_dropdown', items={ {'gui-dropdown.gridtype-increment'}, {'gui-dropdown.gridtype-split'} }, selected_index=1}

    -- DIVISORS
    local divisor_label_flow = menu_frame.add{type='flow', name='divisor_label_flow', direction='horizontal'}
    local divisor_label = divisor_label_flow.add{type='label', name='divisor_label', style='caption_label', caption={'gui-caption.increment-divisor-caption'}}
    divisor_label_flow.style.horizontally_stretchable = true
    divisor_label_flow.style.horizontal_align = 'center'
    -- increment divisor
    local increment_divisor_flow = menu_frame.add{type='flow', name='increment_divisor_flow', direction='horizontal'}
    increment_divisor_flow.style.vertical_align = 'center'
    increment_divisor_flow.style.horizontal_spacing = 8
    local increment_divisor_slider = increment_divisor_flow.add{type='slider', name='increment_divisor_slider', style='notched_slider', minimum_value=1, maximum_value=10, value=5}
    increment_divisor_slider.style.horizontally_stretchable = true
    local increment_divisor_textfield = increment_divisor_flow.add{type='textfield', name='increment_divisor_textfield', style='slider_value_textfield', text='5'}
    increment_divisor_textfield.style.width = 50
    increment_divisor_textfield.style.horizontal_align = 'center'
    -- split divisor
    local split_divisor_flow = menu_frame.add{type='flow', name='split_divisor_flow', direction='horizontal'}
    split_divisor_flow.style.vertical_align = 'center'
    split_divisor_flow.style.horizontal_spacing = 8
    local split_divisor_slider = split_divisor_flow.add{type='slider', name='split_divisor_slider', style='notched_slider', minimum_value=2, maximum_value=12, value=4}
    split_divisor_slider.style.horizontally_stretchable = true
    local split_divisor_textfield = split_divisor_flow.add{type='textfield', name='split_divisor_textfield', text='4'}
    split_divisor_textfield.style.width = 50
    split_divisor_textfield.style.horizontal_align = 'center'

    split_divisor_flow.visible = false

    set_settings_frame_mode(false, player)
end

function lib.open_settings_menu(player)
    local mod_gui = global.player_data[player.index].mod_gui
    local menu_frame = mod_gui.tapeline_menu_frame
    if not menu_frame then
        create_settings_menu(player, mod_gui)
    else
        menu_frame.visible = true
    end
end

function lib.close_settings_menu(player)
    local menu_frame = global.player_data[player.index].mod_gui.tapeline_menu_frame
    if menu_frame then
        menu_frame.visible = false
    end
end

local function on_setting_changed(e) change_setting(e) end

-- step slider, set value of adjoining textfield when slider value changes
local function on_slider(e)
    e.element.slider_value = math.floor(e.element.slider_value + 0.5)
    local textfield = e.element.parent.increment_divisor_textfield or e.element.parent.split_divisor_textfield
    textfield.text = e.element.slider_value
    check_slider_change(e)
end

-- santitize user input and set slider state
local function on_textfield(e)
    local text = e.element.text:gsub('%D','')
    e.element.text = text

    if text == '' or tonumber(text) < 1 or tonumber(text) > 100 then
        e.element.tooltip = 'Must be an integer between 1-100'
        return nil
    else
        e.element.tooltip = ''
    end

    -- set slider value
    local slider = e.element.parent.increment_divisor_slider or e.element.parent.split_divisor_slider
    local max = slider.name == 'increment_divisor_slider' and 10 or 12
    slider.slider_value = math.min(tonumber(text), max)

    change_setting(e)
end

local function on_gridtype_dropdown(e)
    local value = e.element.selected_index
    local increment_flow = e.element.parent.parent.increment_divisor_flow
    local split_flow = e.element.parent.parent.split_divisor_flow
    local label = e.element.parent.parent.divisor_label_flow.divisor_label

    if value == 1 then
        label.caption = {'gui-caption.increment-divisor-caption'}
        increment_flow.visible = true
        split_flow.visible = false
    else
        label.caption = {'gui-caption.split-divisor-caption'}
        increment_flow.visible = false
        split_flow.visible = true
    end

    change_setting(e)
end

-- set frame contents to the specified configuration
local function set_settings_frame_mode(mode, player)
    local player_data = global.player_data[player.index]
    local settings_frame = player_data.mod_gui.tapeline_menu_frame
    local cur_settings

    -- show/hide elements
    if mode then -- editing mode
        global.player_data[player.index].cur_editing = true
        settings_frame.header_flow.visible = true
        settings_frame.header_flow.menu_title.caption={'gui-caption.settings-header-caption', player_data.cur_tilegrid_index}
        settings_frame.checkboxes_flow.visible = false

        cur_settings = global.tilegrids[player_data.cur_tilegrid_index].settings
    else -- drawing mode
        global.player_data[player.index].cur_editing = false
        settings_frame.header_flow.visible = false
        settings_frame.checkboxes_flow.visible = true

        cur_settings = player_data.settings
    end

    settings_frame.gridtype_flow.gridtype_dropdown.selected_index = cur_settings.grid_type
    settings_frame.increment_divisor_flow.increment_divisor_slider.slider_value = cur_settings.increment_divisor
    settings_frame.increment_divisor_flow.increment_divisor_textfield.text = cur_settings.increment_divisor
    settings_frame.split_divisor_flow.split_divisor_slider.slider_value = cur_settings.split_divisor
    settings_frame.split_divisor_flow.split_divisor_textfield.text = cur_settings.split_divisor

    if cur_settings.grid_type == 1 then
        settings_frame.divisor_label_flow.divisor_label.caption = {'gui-caption.increment-divisor-caption'}
        settings_frame.increment_divisor_flow.visible = true
        settings_frame.split_divisor_flow.visible = false
    else
        settings_frame.divisor_label_flow.divisor_label.caption = {'gui-caption.split-divisor-caption'}
        settings_frame.increment_divisor_flow.visible = false
        settings_frame.split_divisor_flow.visible = true
    end
end

local function on_delete_button(e)
    local player = game.players[e.player_index]
    local player_data = global.player_data[e.player_index]

    if e.shift then
        on_dialog_confirm_button(e)
        return nil
    end

    if not player_data.center_gui.tapeline_dialog_frame then
        player_data.mod_gui.tapeline_menu_frame.ignored_by_interaction = true
        create_dialog_menu(player, player_data.center_gui)
    end
end

local function on_confirm_button(e)
    local player = game.players[e.player_index]
    local player_data = global.player_data[e.player_index]

    player_data.mod_gui.tapeline_menu_frame.visible = false

    set_settings_frame_mode(false, player)
end

-- ------------------------------------------------------------
-- TILEGRID SETTINGS BUTTON

-- when a player invokes the 'open-gui' button
function on_leftclick(e)
	local player = game.players[e.player_index]
    local selected = player.selected
    local player_data = global.player_data[e.player_index]

    if selected and selected.name == 'tapeline-settings-button' then
        if player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name == 'tapeline-capsule' then
            player.surface.create_entity {
                name = 'flying-text',
                position = selected.position,
                text = {'flying-text.capsule-warning'}
            }
        else
            for k,v in pairs(global) do
                if type(v) == 'table' and v.button and v.button == selected then
                    player_data.cur_tilegrid_index = k
                    break
                end
            end

            global.player_data[e.player_index] = player_data

            open_settings_menu(player)

            set_settings_frame_mode(true, player)
        end
	end
end

-- settings
gui.on_selection_state_changed('gridtype_dropdown', on_gridtype_dropdown)
gui.on_checked_state_changed('autoclear_checkbox', on_setting_changed)
gui.on_checked_state_changed('restrict_to_cardinals_checkbox', on_setting_changed)
gui.on_value_changed('increment_divisor_slider', on_slider)
gui.on_value_changed('split_divisor_slider', on_slider)
gui.on_text_changed('increment_divisor_textfield', on_textfield)
gui.on_text_changed('split_divisor_textfield', on_textfield)
-- gui buttons
gui.on_click('delete_button', on_delete_button)
gui.on_click('confirm_button', on_confirm_button)