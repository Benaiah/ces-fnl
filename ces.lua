local unpack = (unpack or table.unpack)
local function _0_(tab, v)
local len = #tab
local i = (len + 1)
tab[i] = v
return nil
end
local push = _0_
local function _1_(tab, beginning, length)
local ret = ({})
for i = 1, length do
ret[i] = tab[(beginning + (i - 1))]
end
return ret
end
local slice = _1_
local function _2_()
local x = 0
local function _3_()
x = (x + 1)
return x
end
return _3_
end
local get_genid = _2_
local function _3_(params)
local arity = #params
local pool_arity = (arity + 1)
local pool = ({})
return ({["pool-arity"] = pool_arity, arity = arity, pool = ({})})
end
local component_store_2fcreate = _3_
local function _4_(component_specs)
local genid = ({component = get_genid(), entity = get_genid()})
local world = ({["component-stores"] = ({}), entities = ({}), genid = genid})
for name, params in pairs(component_specs) do
world["component-stores"][name] = component_store_2fcreate(params)
end
return world
end
local world_2fcreate = _4_
local function _5_(store)
return #store.pool
end
local component_store_2fpool_size = _5_
local function _6_(store)
return math.floor((component_store_2fpool_size(store) / store["pool-arity"]))
end
local component_store_2fcount = _6_
local function _7_(store)
return (1 + (component_store_2fpool_size(store) - store["pool-arity"]))
end
local component_store_2flast_component_pool_position = _7_
local function _8_(store, index)
return (1 + ((index - 1) * store["pool-arity"]))
end
local component_store_2fpool_position_from_index = _8_
local function _9_(store, component_index)
local pool_index = (1 + ((component_index - 1) * store["pool-arity"]))
return __fnl_global__component_2dstore_2fget_2dat_2dpool_2dposition(store, pool_index)
end
local component_store_2fget_at = _9_
local function _10_(store, pool_index)
return slice(store.pool, pool_index, store["pool-arity"])
end
local component_store_2fget_at_pool_position = _10_
local function _11_(store)
store[pool] = ({})
return nil
end
local component_store_2fempty = _11_
local function _12_(store, args)
local original_count = #store.pool
for i = 1, store["pool-arity"] do
store.pool[(original_count + i)] = args[i]
end
return nil
end
local component_store_2fcreate_component = _12_
local function _13_(world, entity)
local id = world.genid.entity()
local component_names = ({})
local entity_definition_count = #entity
local i = 1
local done = nil
local component_store = nil
local component_name = nil
local component_args = ({})
local remaining_args = 0
local function _14_()
if not component_store then
component_name = entity[i]
component_store = world["component-stores"][component_name]
remaining_args = component_store.arity
i = (i + 1)
return nil
elseif (remaining_args) > (0) then
push(component_args, entity[i])
remaining_args = (remaining_args - 1)
i = (i + 1)
return nil
elseif "else" then
component_store_2fcreate_component(component_store, ({id, unpack(component_args)}))
push(component_names, component_name)
component_store = nil
component_name = nil
component_args = ({})
if (i) > (entity_definition_count) then
done = true
return nil
end
end
end
__fnl_global___2awhile(not done, _14_())
world.entities[id] = component_names
return id
end
local world_2fcreate_entity = _13_
local function _14_(store, entities_to_update)
local pool = store.pool
local pool_arity = store["pool-arity"]
local arity = store.arity
for i = 1, #pool, pool_arity do
local entity_update = entities_to_update[pool[i]]
local function _15_()
if entity_update then
for j = 1, arity do
local val = entity_update[j]
local function _15_()
if val then
pool[(i + j)] = val
return nil
end
end
_15_()
end
return nil
end
end
_15_()
end
return nil
end
local component_store_2frun_updates = _14_
local function _15_(store, entities_to_remove)
local pool = store.pool
local pool_arity = store["pool-arity"]
local pool_length = component_store_2fpool_size(store)
local i_of_last_id = (1 + (pool_length - pool_arity))
for i = 1, pool_length, pool_arity do
local function _16_()
if entities_to_remove[pool[i]] then
pool[i] = nil
return nil
end
end
_16_()
end
local done = nil
local i = 1
local copy_from_i = nil
local it = pool[i]
local function _16_()
if (it) == (nil) then
local function _16_()
if not copy_from_i then
copy_from_i = i
return nil
end
end
_16_()
local j = (copy_from_i + pool_arity)
copy_from_i = nil
local function _17_()
if pool[j] then
copy_from_i = j
return nil
end
end
j = (j + pool_arity)
__fnl_global___2awhile(((j) <= (i_of_last_id) and not copy_from_i), _17_(), nil)
local function _18_()
if not copy_from_i then
for j = i, pool_length do
pool[j] = nil
end
done = true
return nil
end
end
_18_()
if copy_from_i then
for j = 0, (pool_arity - 1) do
pool[(i + j)] = pool[(copy_from_i + j)]
end
pool[copy_from_i] = nil
return nil
end
end
end
i = (i + pool_arity)
return __fnl_global___2awhile(not done, nil, _16_(), nil)
end
local component_store_2frun_removals = _15_
local function _16_(world, components_updates)
for component_name, component_updates in pairs(components_updates) do
component_store_2frun_updates(world["component-stores"][component_name], component_updates)
end
return nil
end
local world_2frun_updates = _16_
local function _17_(world, entity_removals)
local components_removals = ({})
local entities = world.entities
local stores_requiring_removals = ({})
for id, _ in pairs(entity_removals) do
local components_list = entities[id]
for i = 1, #components_list do
local component_name = components_list[i]
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
local world_2frun_removals = _17_
local function _18_(world, new_entities)
local ids = ({})
for i = 1, #new_entities do
push(ids, world_2fcreate_entity(world, new_entities[i]))
end
return ids
end
local world_2frun_creations = _18_
local function _19_(world)
for _, component_store in pairs(__fnl_global__component_2dstores) do
component_store_2fempty(component_store)
end
world["entities"] = ({})
return nil
end
local world_2fempty = _19_
local function _20_(fun, extra_arg, component_stores)
local num_stores = #component_stores
local end_positions = ({})
local indices = ({})
local positions = ({})
for i = 1, num_stores do
push(indices, 1)
push(end_positions, component_store_2flast_component_pool_position(component_stores[i]))
push(positions, 1)
end
local done = nil
local all_identical = true
local entity_id = nil
for i = 1, num_stores do
local store = component_stores[i]
local pos = positions[i]
local this_id = store.pool[pos]
local function _21_()
if not entity_id then
entity_id = this_id
return nil
else
if (this_id) ~= (entity_id) then
all_identical = false
return nil
end
end
end
_21_()
end
local function _21_()
if (all_identical and entity_id) then
local components = ({})
for i = 1, num_stores do
local store = component_stores[i]
local index = indices[i]
local pos = positions[i]
push(components, component_store_2fget_at_pool_position(store, pos))
indices[i] = (index + 1)
positions[i] = (pos + store["pool-arity"])
end
return fun(extra_arg, unpack(components))
elseif "else" then
local i = 1
local increased_an_index = false
local function _21_()
local function _22_()
if (num_stores) ~= (i) then
local index = indices[i]
local next_index = indices[(i + 1)]
if (index) < (next_index) then
local store = component_stores[i]
local pos = positions[i]
indices[i] = (index + 1)
positions[i] = (pos + store["pool-arity"])
increased_an_index = true
return nil
end
end
end
_22_()
local function _23_()
if (num_stores) == (i) then
local index = indices[i]
local pos = positions[i]
local store = component_stores[i]
indices[i] = (index + 1)
positions[i] = (pos + store["pool-arity"])
increased_an_index = true
return nil
end
end
_23_()
i = (i + 1)
return nil
end
return __fnl_global___2awhile(not increased_an_index, _21_())
end
end
done = true
for i = 1, num_stores do
local function _22_()
if (positions[i]) < (end_positions[i]) then
done = false
return nil
end
end
_22_()
end
return __fnl_global___2awhile(not done, nil, nil, nil, _21_(), nil, nil)
end
local component_store_2fcall_on_common_components = _20_
local function _21_(world, component_names, fun, extra_arg)
local function _22_()
local stores = ({})
for i = 0, #component_names do
push(stores, world["component-stores"][component_names[i]])
end
return stores
end
return component_store_2fcall_on_common_components(fun, extra_arg, _22_())
end
local world_2fcall_on_common_components = _21_
return ({["component-store"] = ({["call-on-common-components"] = component_store_2fcall_on_common_components, ["common-entities-3"] = __fnl_global__component_2dstore_2fcommon_2dentities_2d3, ["create-component"] = component_store_2fcreate_component, ["get-at"] = component_store_2fget_at, ["last-component-pool-position"] = component_store_2flast_component_pool_position, ["pool-size"] = component_store_2fpool_size, ["run-removals"] = component_store_2frun_removals, ["run-updates"] = component_store_2frun_updates, count = component_store_2fcount, create = component_store_2fcreate, empty = component_store_2fempty}), world = ({["call-on-common-components"] = world_2fcall_on_common_components, ["create-entity"] = world_2fcreate_entity, ["run-creations"] = world_2frun_creations, ["run-removals"] = world_2frun_removals, ["run-updates"] = world_2frun_updates, create = world_2fcreate, empty = world_2fempty})})