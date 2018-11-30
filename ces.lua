local unpack = (unpack or table.unpack)
local function push_at(tab, index, v, ...)
  if v then
    tab[index] = v
    local next_index = (index + 1)
    return push_at(tab, next_index, ...)
  end
end
local function push(tab, ...)
  local index = (#tab + 1)
  return push_at(tab, index, ...)
end
local function slice(tab, beginning, length)
  local ret = {}
  local real_beginning = (beginning - 1)
  for i = 1, length do
    ret[i] = tab[(real_beginning + i)]
  end
  return ret
end
local function concat_21(tab1, tab2)
  local tab1_len = #tab1
  for i = 1, #tab2 do
    push_at(tab1, (tab1_len + i), tab2[i])
  end
  return nil
end
local function concat(tab1, tab2)
  local result = {}
  local tab1_len = #tab1
  for i = 1, tab1_len do
    push_at(result, 1, tab1[i])
  end
  for i = 1, #tab2 do
    push_at(result, (tab1_len + i), tab2[i])
  end
  return result
end
local function get_genid()
  local x = 0
  local function _0_()
    x = (x + 1)
    return x
  end
  return _0_
end
local function component_store_2fpool_size(store)
  return store["pool-size"]
end
local function component_store_2fcount(store)
  return math.floor((component_store_2fpool_size(store) / store["pool-arity"]))
end
local function component_store_2fcreate(name, params)
  local arity = #params
  local pool_arity = (arity + 1)
  local name = (name or "(anonymous)")
  return {["pool-arity"] = pool_arity, ["pool-size"] = 0, __inspect__ = __fnl_global__component_2dstore_2fview, arity = arity, name = name, params = params, pool = {}}
end
local function world_2fcreate(component_specs)
  local genid = {component = get_genid(), entity = get_genid()}
  local world = {["component-stores"] = {}, entities = {}, genid = genid}
  for name, params in pairs(component_specs) do
    world["component-stores"][name] = component_store_2fcreate(name, params)
  end
  return world
end
local function component_store_2flast_component_pool_position(store)
  return (1 + (component_store_2fpool_size(store) - store["pool-arity"]))
end
local function component_store_2fpool_position_from_index(store, index)
  return (1 + ((index - 1) * store["pool-arity"]))
end
local function component_store_2fget_id_at(store, component_index)
  local pool_index = component_store_2fpool_position_from_index(store, component_index)
  return store.pool[pool_index]
end
local function component_store_2fget_at_pool_position(store, pool_index)
  return slice(store.pool, pool_index, store["pool-arity"])
end
local function component_store_2fget_at(store, component_index)
  local pool_index = (1 + ((component_index - 1) * store["pool-arity"]))
  return component_store_2fget_at_pool_position(store, pool_index)
end
local function component_store_2fget_by_id(store, id)
  local i = 1
  local result = nil
  local done = nil
  while not done do
    local id_here = store.pool[i]
    local function _0_()
      if (id_here == id) then
        result = component_store_2fget_at_pool_position(store, i)
        done = true
        return nil
      end
    end
    _0_()
    i = (i + store["pool-arity"])
    local function _1_()
      if ((id_here == nil) or (id_here > id)) then
        done = true
        return nil
      end
    end
    _1_()
  end
  return result
end
local function component_store_2fempty(store)
  store["pool"] = {}
  return nil
end
local function component_store_2fcreate_component(store, args)
  local original_count = component_store_2fpool_size(store)
  store["pool-size"] = (original_count + store["pool-arity"])
  for i = 1, store["pool-arity"] do
    store.pool[(original_count + i)] = args[i]
  end
  return nil
end
local function world_2fcreate_entity(world, entity)
  local id = world.genid.entity()
  local component_names = {}
  local entity_definition_count = #entity
  local i = 1
  local done = nil
  local component_store = nil
  local component_name = nil
  local component_args = {}
  local remaining_args = 0
  while not done do
    local function _0_()
      if not component_store then
        component_name = entity[i]
        component_store = world["component-stores"][component_name]
        remaining_args = component_store.arity
        i = (i + 1)
        return nil
      elseif (remaining_args > 0) then
        push(component_args, entity[i])
        remaining_args = (remaining_args - 1)
        i = (i + 1)
        return nil
      elseif "else" then
        component_store_2fcreate_component(component_store, {id, unpack(component_args)})
        component_names[component_name] = true
        component_store = nil
        component_name = nil
        component_args = {}
        if (i > entity_definition_count) then
          done = true
          return nil
        end
      end
    end
    _0_()
  end
  world.entities[id] = component_names
  return id
end
local function world_2fget_by_id(world, entity_id)
  local component_names = world.entities[entity_id]
  local result = {}
  for component_store_name, _ in pairs(component_names) do
    local component_store = world["component-stores"][component_store_name]
    local component_data = component_store_2fget_by_id(component_store, entity_id)
    local component_data_sans_id = slice(component_data, 2, (component_store["pool-arity"] - 1))
    push(result, component_store_name, unpack(component_data_sans_id))
  end
  return result
end
local function world_2fget_table_by_id(world, entity_id)
  local component_names = world.entities[entity_id]
  if component_names then
    local result = {}
    for component_store_name, _ in pairs(component_names) do
      local component_store = world["component-stores"][component_store_name]
      local component_data = component_store_2fget_by_id(component_store, entity_id)
      local component_data_sans_id = slice(component_data, 2, (component_store["pool-arity"] - 1))
      result[component_store_name] = component_data_sans_id
    end
    return result
  end
end
local function all(list, fun)
  local result = true
  local done = false
  local i = 1
  while (result and not done) do
    local el = list[i]
    local function _0_()
      if not fun(el) then
        result = false
        done = true
        return nil
      end
    end
    _0_()
    i = (i + 1)
  end
  return result
end
local function any(list, fun)
  local result = false
  for i, el in ipairs(list) do
    local function _0_()
      if fun(el) then
        result = true
        return nil
      end
    end
    _0_()
  end
  return result
end
local function world_2fselect_entities_with_components(world, component_type_names)
  local results = {}
  for id, entity_components in pairs(world.entities) do
    local function _0_()
      local function _0_(name)
        return entity_components[name]
      end
      if all(component_type_names, _0_) then
        return push(results, id)
      end
    end
    _0_()
  end
  return results
end
local function component_store_2frun_updates(store, entities_to_update)
  local pool = store.pool
  local pool_arity = store["pool-arity"]
  local arity = store.arity
  for i = 1, #pool, pool_arity do
    local entity_update = entities_to_update[pool[i]]
    local function _0_()
      if entity_update then
        for j = 1, arity do
          local val = entity_update[j]
          local function _0_()
            if val then
              pool[(i + j)] = val
              return nil
            end
          end
          _0_()
        end
        return nil
      end
    end
    _0_()
  end
  return nil
end
local function component_store_2frun_removals(store, entities_to_remove)
  local pool = store.pool
  local pool_arity = store["pool-arity"]
  local pool_size = component_store_2fpool_size(store)
  local i_of_last_id = (1 + (pool_size - pool_arity))
  for i = 1, pool_size, pool_arity do
    local function _0_()
      if entities_to_remove[pool[i]] then
        store["pool-size"] = (store["pool-size"] - pool_arity)
        pool[i] = nil
        return nil
      end
    end
    _0_()
  end
  local done = nil
  local i = 1
  local copy_from_i = nil
  while not done do
    local it = pool[i]
    local function _0_()
      if (it == nil) then
        local function _0_()
          if not copy_from_i then
            copy_from_i = i
            return nil
          end
        end
        _0_()
        local j = (copy_from_i + pool_arity)
        copy_from_i = nil
        while ((j <= i_of_last_id) and not copy_from_i) do
          local function _1_()
            if pool[j] then
              copy_from_i = j
              return nil
            end
          end
          _1_()
          j = (j + pool_arity)
        end
        local function _1_()
          if not copy_from_i then
            for j = i, pool_size do
              pool[j] = nil
            end
            done = true
            return nil
          end
        end
        _1_()
        if copy_from_i then
          for j = 0, (pool_arity - 1) do
            pool[(i + j)] = pool[(copy_from_i + j)]
          end
          pool[copy_from_i] = nil
          return nil
        end
      end
    end
    _0_()
    i = (i + pool_arity)
  end
  return nil
end
local function world_2frun_updates(world, components_updates)
  for component_name, component_updates in pairs(components_updates) do
    component_store_2frun_updates(world["component-stores"][component_name], component_updates)
  end
  return nil
end
local function world_2frun_removals(world, entity_removals)
  local components_removals = {}
  local entities = world.entities
  local stores_requiring_removals = {}
  for id, _ in pairs(entity_removals) do
    local components_set = entities[id]
    for component_name, _ in pairs(components_set) do
      stores_requiring_removals[component_name] = true
      do local _ = (stores_requiring_removals[component_name] or nil) end
    end
    entities[id] = nil
  end
  for component_name, _ in pairs(stores_requiring_removals) do
    local store = world["component-stores"][component_name]
    component_store_2frun_removals(store, entity_removals)
  end
  return nil
end
local function world_2frun_creations(world, new_entities)
  local ids = {}
  for i = 1, #new_entities do
    push(ids, world_2fcreate_entity(world, new_entities[i]))
  end
  return ids
end
local function world_2fempty(world)
  for _, component_store in pairs(world["component-stores"]) do
    component_store_2fempty(component_store)
  end
  world["entities"] = {}
  return nil
end
local function component_store_2fcall_on_common_components(fun, static_argument, component_stores, should_debug)
  local num_stores = #component_stores
  local end_indices = {}
  local indices = {}
  local ids = {}
  for i = 1, num_stores do
    push(indices, 1)
    push(end_indices, (1 + component_store_2fcount(component_stores[i])))
  end
  local done = nil
  local all_identical = true
  local entity_id = nil
  while not done do
    all_identical = true
    entity_id = nil
    for i = 1, num_stores do
      local store = component_stores[i]
      local index = indices[i]
      local this_id = component_store_2fget_id_at(store, index)
      ids[i] = this_id
      local function _0_()
        if not entity_id then
          entity_id = this_id
          return nil
        end
      end
      _0_()
      local function _1_()
        if (this_id ~= entity_id) then
          all_identical = false
          return nil
        end
      end
      _1_()
    end
    local function _0_()
      if (all_identical and entity_id) then
        local components = {}
        for i = 1, num_stores do
          local store = component_stores[i]
          local index = indices[i]
          push(components, component_store_2fget_at(store, index))
          indices[i] = (index + 1)
        end
        return fun(static_argument, unpack(components))
      elseif "else" then
        local i = num_stores
        local increased_an_index = false
        while not increased_an_index do
          local function _0_()
            if (i > 1) then
              local index = indices[i]
              local next_index = indices[(i - 1)]
              local id_at_index = ids[i]
              local id_at_next_index = ids[(i - 1)]
              if (id_at_index < id_at_next_index) then
                local store = component_stores[i]
                indices[i] = (index + 1)
                increased_an_index = true
                return nil
              end
            elseif "else" then
              local index = indices[i]
              local stores = component_stores[i]
              indices[i] = (index + 1)
              increased_an_index = true
              return nil
            end
          end
          _0_()
          i = (i - 1)
        end
        return nil
      end
    end
    _0_()
    for i = 1, num_stores do
      local function _1_()
        if (not done and (indices[i] >= end_indices[i])) then
          done = true
          return nil
        end
      end
      _1_()
    end
  end
  return nil
end
local function world_2fcall_on_common_components(world, component_names, fun, extra_arg)
  local function _0_()
    local stores = {}
    for i = 1, #component_names do
      push(stores, world["component-stores"][component_names[i]])
    end
    return stores
  end
  return component_store_2fcall_on_common_components(fun, extra_arg, _0_())
end
return {__internal__ = {["component-store"] = {["call-on-common-components"] = component_store_2fcall_on_common_components, ["create-component"] = component_store_2fcreate_component, ["get-at"] = component_store_2fget_at, ["get-by-id"] = component_store_2fget_by_id, ["last-component-pool-position"] = component_store_2flast_component_pool_position, ["pool-size"] = component_store_2fpool_size, ["run-removals"] = component_store_2frun_removals, ["run-updates"] = component_store_2frun_updates, count = component_store_2fcount, create = component_store_2fcreate, empty = component_store_2fempty}}, world = {["call-on-common-components"] = world_2fcall_on_common_components, ["create-entity"] = world_2fcreate_entity, ["get-by-id"] = world_2fget_by_id, ["get-table-by-id"] = world_2fget_table_by_id, ["run-creations"] = world_2frun_creations, ["run-removals"] = world_2frun_removals, ["run-updates"] = world_2frun_updates, ["select-entities-with-components"] = world_2fselect_entities_with_components, create = world_2fcreate, empty = world_2fempty}}
