local end_wait = 3

-- set up constants
function on_init()

    global.next_tilegrid_index = global.next_tilegrid_index or 1
    global.perish = global.perish or {}

end

function on_load()

    if game.is_multiplayer then end_wait = 90; game.print('Multiplayer detected, end_wait increased') end

end

-- check to see if a tilegrid drag has finished
function on_tick()

    local cur_tick = game.ticks_played

    -- for each player in player_data, if they're doing a drag, check to see if it's finished
    stdlib.table.each(global.player_data, function(t,i)
        if t.cur_drawing and cur_tick - t.last_capsule_tick > end_wait then
            t.cur_drawing = false
            local data = global[t.cur_tilegrid_index]
            local from_pos = stdlib.tile.from_position
            if not stdlib.position.equals(from_pos(t.last_capsule_pos), from_pos(data.origin)) then
                if data.settings.grid_autoclear then global.perish[t.cur_tilegrid_index] = game.ticks_played + data.time_to_live
                else create_settings_button(global[t.cur_tilegrid_index]) end
                if data.settings.log_selection_area then data.player.print('Dimensions: ' .. data.area.width .. 'x' .. data.area.height) end
            else
                destroy_tilegrid_data(t.cur_tilegrid_index)
            end
            global.player_data[i] = t
        end
    end)

    stdlib.table.each(global.perish, function(v,k)
        if v <= game.ticks_played then
            destroy_tilegrid_data(k)
            global.perish[k] = nil
        end
    end)

end

-- when a capsule is thrown
function on_capsule(e)  -- EVENT ARGUMENTS: player_index, item, position

    if e.item.name ~= 'tapeline-capsule' then return end

    local player_data = global.player_data[e.player_index]

    if game.ticks_played - player_data.last_capsule_tick > 3 then
        -- create tilegrid
        player_data.cur_tilegrid_index = global.next_tilegrid_index
        player_data.cur_drawing = true
        global[global.next_tilegrid_index] = construct_tilegrid_data(e)
        global.next_tilegrid_index = global.next_tilegrid_index + 1
    else
        local from_pos = stdlib.tile.from_position
        local cur_pos = e.position
        if not stdlib.position.equals(from_pos(player_data.last_capsule_pos), from_pos(cur_pos)) then
            -- if ignore cardinals, adjust thrown position
            if player_data.settings.restrict_to_cardinals then
                local tilegrid = global[player_data.cur_tilegrid_index]
                local cur_tile = from_pos(cur_pos)
                if math.abs(cur_tile.x - tilegrid.origin.x) >= math.abs(cur_tile.y - tilegrid.origin.y) then
                    cur_pos.y = tilegrid.origin.y
                else
                    cur_pos.x = tilegrid.origin.x
                end
            end
            -- update tilegrid data
            update_tilegrid_data(e)
        end
    end

    player_data.last_capsule_pos = e.position
    player_data.last_capsule_tick = game.ticks_played
    global.player_data[e.player_index] = player_data
    global[player_data.cur_tilegrid_index].time_of_creation = game.ticks_played
	
end

-- create a new tilegrid data structure in GLOBAL
function construct_tilegrid_data(e)

    local data = {}
    -- initial settings
    data.player = game.players[e.player_index]
    data.settings = global.player_data[e.player_index].settings
    -- area
    data.area = stdlib.area.construct(e.position.x, e.position.y, e.position.x, e.position.y):normalize():ceil():corners()
    data.area.size,data.area.width,data.area.height = data.area:size()
    data.area.midpoints = stdlib.area.center(data.area)
    -- metadata
    data.origin = stdlib.position.add(data.area.left_top, { x = 0.5, y = 0.5 })
    data.time_of_creation = game.ticks_played
    data.time_to_live = data.settings.tilegrid_clear_delay
    -- anchors
    data.anchors = {}
    data.anchors.horizontal = 'top'
    data.anchors.vertical = 'left'
    -- tilegrid divisors
	data.tilegrid_divisors = {}
	if data.settings.grid_type == 2 then
		data.tilegrid_divisors[1] = { x = 1, y = 1 }
		data.tilegrid_divisors[2] = { x = (data.area.width > 1 and (data.area.width / data.settings.split_divisor) or data.area.width), y = (data.area.height > 1 and (data.area.height / data.settings.split_divisor) or data.area.height) }
		data.tilegrid_divisors[3] = { x = (data.area.width > 1 and (data.area.midpoints.x - data.area.left_top.x) or data.area.width), y = (data.area.height > 1 and (data.area.midpoints.y - data.area.left_top.y) or data.area.height) }
	else
		for i=1,4 do
			table.insert(data.tilegrid_divisors, { x = data.settings.increment_divisor ^ (i - 1), y = data.settings.increment_divisor ^ (i - 1) })
		end
    end
    -- render objects
    data.render_objects = build_render_objects(data)

    return data

end

-- update a tilegrid
function update_tilegrid_data(e)

    data = global[global.player_data[e.player_index].cur_tilegrid_index]
    -- find new corners
    local left_top = { x = (e.position.x < data.origin.x and e.position.x or data.origin.x), y = (e.position.y < data.origin.y and e.position.y or data.origin.y) }
    local right_bottom = { x = (e.position.x > data.origin.x and e.position.x or data.origin.x), y = (e.position.y > data.origin.y and e.position.y or data.origin.y) }
    -- update area
    data.area = stdlib.area.construct(left_top.x, left_top.y, right_bottom.x, right_bottom.y):normalize():ceil():corners()
    data.area.size,data.area.width,data.area.height = data.area:size()
    data.area.midpoints = stdlib.area.center(data.area)
    -- update anchors
    if e.position.x < data.origin.x then
        if e.position.y < data.origin.y then
            data.anchors.horizontal = 'bottom'
            data.anchors.vertical = 'right'
        else
            data.anchors.horizontal = 'top'
            data.anchors.vertical = 'right'
        end
    elseif e.position.y < data.origin.y then
        data.anchors.horizontal = 'bottom'
        data.anchors.vertical = 'left'
    else
        data.anchors.horizontal = 'top'
        data.anchors.vertical = 'left'
    end
    -- update tilegrid divisors
    if data.settings.grid_type == 2 then
        data.tilegrid_divisors[2] = { x = (data.area.width > 1 and (data.area.width / data.settings.split_divisor) or data.area.width), y = (data.area.height > 1 and (data.area.height / data.settings.split_divisor) or data.area.height) }
        data.tilegrid_divisors[3] = { x = (data.area.width > 1 and (data.area.midpoints.x - data.area.left_top.x) or data.area.width), y = (data.area.height > 1 and (data.area.midpoints.y - data.area.left_top.y) or data.area.height) }
    end
    -- destroy and rebuild render objects
    destroy_render_objects(data.render_objects)
    data.render_objects = build_render_objects(data)
    -- update global table
    global[global.player_data[e.player_index].cur_tilegrid_index] = data

end

-- destroy a tilegrid's data
function destroy_tilegrid_data(tilegrid_index)

    destroy_render_objects(global[tilegrid_index].render_objects)
    if global[tilegrid_index].button then global[tilegrid_index].button.destroy() end
    global[tilegrid_index] = nil

end

stdlib.event.register('on_init', on_init)
-- stdlib.event.register('on_load', on_load)
stdlib.event.register(defines.events.on_player_used_capsule, on_capsule)
stdlib.event.register(defines.events.on_tick, on_tick)