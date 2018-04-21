local unpack = (unpack or table.unpack)
local function push(tab, v)
local len = #tab
local i = (len + 1)
tab[i] = v
return nil
end
do local _ = push end
local function slice(tab, beginning, length)
local ret = ({})
for i = 1, length do
ret[i] = tab[(beginning + (i - 1))]
end
return ret
end
do local _ = slice end
local function get_genid()
local x = 0
local function _0_()
x = (x + 1)
return x
end
return _0_
end
do local _ = get_genid end
local function component_store_2fcreate(params)
local arity = #params
local pool_arity = (arity + 1)
local pool = ({})
return ({["pool-arity"] = pool_arity, arity = arity, pool = ({})})
end
do local _ = component_store_2fcreate end
local function world_2fcreate(component_specs)
local genid = ({component = get_genid(), entity = get_genid()})
local world = ({["component-stores"] = ({}), entities = ({}), genid = genid})
for name, params in pairs(component_specs) do
world["component-stores"][name] = component_store_2fcreate(params)
end
return world
end
do local _ = world_2fcreate end
local function component_store_2fpool_size(store)
return #store.pool
end
do local _ = component_store_2fpool_size end
local function component_store_2fcount(store)
return math.floor((component_store_2fpool_size(store) / store["pool-arity"]))
end
do local _ = component_store_2fcount end
local function component_store_2flast_component_pool_position(store)
return (1 + (component_store_2fpool_size(store) - store["pool-arity"]))
end
do local _ = component_store_2flast_component_pool_position end
local function component_store_2fpool_position_from_index(store, index)
return (1 + ((index - 1) * store["pool-arity"]))
end
do local _ = component_store_2fpool_position_from_index end
local function component_store_2fget_id_at(store, component_index)
local pool_index = component_store_2fpool_position_from_index(store, component_index)
return store.pool[pool_index]
end
do local _ = component_store_2fget_id_at end
local function component_store_2fget_at_pool_position(store, pool_index)
return slice(store.pool, pool_index, store["pool-arity"])
end
do local _ = component_store_2fget_at_pool_position end
local function component_store_2fget_at(store, component_index)
local pool_index = (1 + ((component_index - 1) * store["pool-arity"]))
return component_store_2fget_at_pool_position(store, pool_index)
end
do local _ = component_store_2fget_at end
local function component_store_2fempty(store)
store[pool] = ({})
return nil
end
do local _ = component_store_2fempty end
local function component_store_2fcreate_component(store, args)
local original_count = #store.pool
for i = 1, store["pool-arity"] do
store.pool[(original_count + i)] = args[i]
end
return nil
end
do local _ = component_store_2fcreate_component end
local function world_2fcreate_entity(world, entity)
local id = world.genid.entity()
local component_names = ({})
local entity_definition_count = #entity
local i = 1
local done = nil
local component_store = nil
local component_name = nil
local component_args = ({})
local remaining_args = 0
while not done do
local function _0_()
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
_0_()
end
world.entities[id] = component_names
return id
end
do local _ = world_2fcreate_entity end
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
do local _ = component_store_2frun_updates end
local function component_store_2frun_removals(store, entities_to_remove)
local pool = store.pool
local pool_arity = store["pool-arity"]
local pool_length = component_store_2fpool_size(store)
local i_of_last_id = (1 + (pool_length - pool_arity))
for i = 1, pool_length, pool_arity do
local function _0_()
if entities_to_remove[pool[i]] then
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
if (it) == (nil) then
local function _0_()
if not copy_from_i then
copy_from_i = i
return nil
end
end
_0_()
local j = (copy_from_i + pool_arity)
copy_from_i = nil
while ((j) <= (i_of_last_id) and not copy_from_i) do
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
for j = i, pool_length do
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
do local _ = component_store_2frun_removals end
local function world_2frun_updates(world, components_updates)
for component_name, component_updates in pairs(components_updates) do
component_store_2frun_updates(world["component-stores"][component_name], component_updates)
end
return nil
end
do local _ = world_2frun_updates end
local function world_2frun_removals(world, entity_removals)
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
do local _ = world_2frun_removals end
local function world_2frun_creations(world, new_entities)
local ids = ({})
for i = 1, #new_entities do
push(ids, world_2fcreate_entity(world, new_entities[i]))
end
return ids
end
do local _ = world_2frun_creations end
local function world_2fempty(world)
for _, component_store in pairs(__fnl_global__component_2dstores) do
component_store_2fempty(component_store)
end
world["entities"] = ({})
return nil
end
do local _ = world_2fempty end
local function component_store_2fcall_on_common_components(fun, static_argument, component_stores)
local num_stores = #component_stores
local end_indices = ({})
local indices = ({})
for i = 1, num_stores do
push(indices, 1)
push(end_indices, component_store_2fcount(component_stores[i]))
end
local done = nil
local all_identical = true
local entity_id = nil
while not done do
all_identical = true
entity_id = nil
local this_ids = ({})
for i = 1, num_stores do
local store = component_stores[i]
local index = indices[i]
local this_id = component_store_2fget_id_at(store, index)
push(this_ids, this_id)
local function _0_()
if not entity_id then
entity_id = this_id
return nil
end
end
_0_()
local function _1_()
if (this_id) ~= (entity_id) then
all_identical = false
return nil
end
end
_1_()
end
local function _0_()
if (all_identical and entity_id) then
local components = ({})
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
if (i) > (1) then
local index = indices[i]
local next_index = indices[(i - 1)]
if (index) < (next_index) then
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
done = true
for i = 1, num_stores do
local function _1_()
if (done and (indices[i]) < (end_indices[i])) then
done = false
return nil
end
end
_1_()
end
end
return nil
end
do local _ = component_store_2fcall_on_common_components end
local function world_2fcall_on_common_components(world, component_names, fun, extra_arg)
local function _0_()
local stores = ({})
for i = 0, #component_names do
push(stores, world["component-stores"][component_names[i]])
end
return stores
end
return component_store_2fcall_on_common_components(fun, extra_arg, _0_())
end
do local _ = world_2fcall_on_common_components end
return ({["component-store"] = ({["call-on-common-components"] = component_store_2fcall_on_common_components, ["common-entities-3"] = __fnl_global__component_2dstore_2fcommon_2dentities_2d3, ["create-component"] = component_store_2fcreate_component, ["get-at"] = component_store_2fget_at, ["last-component-pool-position"] = component_store_2flast_component_pool_position, ["pool-size"] = component_store_2fpool_size, ["run-removals"] = component_store_2frun_removals, ["run-updates"] = component_store_2frun_updates, count = component_store_2fcount, create = component_store_2fcreate, empty = component_store_2fempty}), world = ({["call-on-common-components"] = world_2fcall_on_common_components, ["create-entity"] = world_2fcreate_entity, ["run-creations"] = world_2frun_creations, ["run-removals"] = world_2frun_removals, ["run-updates"] = world_2frun_updates, create = world_2fcreate, empty = world_2fempty})})