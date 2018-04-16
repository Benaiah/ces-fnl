(local unpack (or unpack table.unpack))
(local push (fn [tab v]
              (let [len (# tab)
                    i (+ len 1)]
                (tset tab i v))))

;; this slice only supports going forward, and uses beginning + length
;; instead of beginning + end
(local slice (fn [tab beginning length]
               (local ret [])
               (for [i 1 length]
                 (tset ret i (. tab (+ beginning (- i 1)))))
               ret))

(local get-genid (fn [] (var x 0) (fn [] (set x (+ x 1)) x)))

(local component-store/create
       (fn [params]
         (let [arity (# params)
               pool-arity (+ arity 1)
               pool []]
           {:arity arity
            :pool-arity pool-arity
            :pool []})))

(local world/create
       (fn [component-specs]
         (let [genid {:component (get-genid)
                      :entity (get-genid)}
               world {:entities {}
                      :component-stores {}
                      :genid genid}]
           (each [name params (pairs component-specs)]
             (tset world.component-stores name (component-store/create params)))
           world)))

(local component-store/pool-size (fn [store] (# store.pool)))

(local component-store/count
       (fn [store] (math.floor (/ (component-store/pool-size store) store.pool-arity))))

(local component-store/last-component-pool-position
       (fn [store] (+ 1 (- (component-store/pool-size store) store.pool-arity))))

(local component-store/pool-position-from-index
       (fn [store index] (+ 1 (* (- index 1) store.pool-arity))))

(local component-store/get-at
       (fn [store component-index]
         (let [pool-index (+ 1 (* (- component-index 1) store.pool-arity))]
           (component-store/get-at-pool-position store pool-index))))

(local component-store/get-at-pool-position
       (fn [store pool-index]
         (slice store.pool pool-index store.pool-arity)))

(local component-store/empty (fn [store] (tset store pool [])))

(local component-store/create-component
       (fn [store args]
         (let [original-count (# store.pool)]
           (for [i 1 store.pool-arity]
             (tset store.pool (+ original-count i) (. args i))))))

(local world/create-entity
       (fn [world entity]
         (let [id (world.genid.entity)
               component-names []]
           (local entity-definition-count (# entity))
           (var i 1)
           (var done nil)
           (var component-store nil)
           (var component-name nil)
           (var component-args [])
           (var remaining-args 0)
           (while (not done)
             (if (not component-store)
                 (do
                   (set component-name (. entity i))
                   (set component-store (. world.component-stores component-name))
                   (set remaining-args (. component-store :arity))
                   (set i (+ i 1)))

                 (> remaining-args 0)
                 (do (push component-args (. entity i))
                     (set remaining-args (- remaining-args 1))
                     (set i (+ i 1)))

                 :else
                 (do (component-store/create-component component-store [id (unpack component-args)])
                     (push component-names component-name)
                     (set component-store nil)
                     (set component-name nil)
                     (set component-args [])
                     (when (> i entity-definition-count)
                       (do (set done true))))))
           (tset world.entities id component-names)
           id)))

(local component-store/run-updates
       (fn [store entities-to-update]
         (let [pool store.pool
               pool-arity store.pool-arity
               arity store.arity]
           (for [i 1 (# pool) pool-arity]
             (local entity-update (. entities-to-update (. pool i)))
             (when entity-update
               (for [j 1 arity]
                 (local val (. entity-update j))
                 (when val (tset pool (+ i j) val))))))))

(local component-store/run-removals
       (fn [store entities-to-remove]
         (let [pool store.pool
               pool-arity store.pool-arity
               pool-length (component-store/pool-size store)
               i-of-last-id (+ 1 (- pool-length pool-arity))]

           ;; We only need to set the entity ID to nil -
           ;; since we know the arity, the compactor will
           ;; know how much to replace 
           (for [i 1 pool-length pool-arity]
             (when (. entities-to-remove (. pool i))
               (tset pool i nil)))

           ;; The compactor only needs to check the entity
           ;; IDs to tell if a component needs removal
           (var done nil)
           (var i 1)
           (var copy-from-i nil)
           (while (not done)
             (local it (. pool i))
             (when (= it nil)
               ;; find the index of the next component that's
               ;; not being removed, starting from the index
               ;; of the last non-removed component we found
               (when (not copy-from-i)
                 (set copy-from-i i))
               (var j (+ copy-from-i pool-arity))
               (set copy-from-i nil)
               (while (and (<= j i-of-last-id) (not copy-from-i))
                 (when (. pool j) (set copy-from-i j))
                 (set j (+ j pool-arity)))

               ;; if there aren't any live components left in
               ;; the pool, erase the rest of it
               (when (not copy-from-i)
                 (for [j i pool-length]
                   (tset pool j nil))
                 (set done true))

               (when copy-from-i
                 ;; copy the next live component to this position
                 (for [j 0 (- pool-arity 1)]
                   (tset pool (+ i j) (. pool (+ copy-from-i j))))
                 ;; set that component's entity ID to nil
                 (tset pool copy-from-i nil)))
             (set i (+ i pool-arity))))))

(local world/run-updates
       (fn [world components-updates]
         (each [component-name component-updates (pairs components-updates)]
           (component-store/run-updates (. (. world :component-stores) component-name)
                                        component-updates))))

(local world/run-removals
       (fn [world entity-removals]
         (local components-removals {})
         (local entities world.entities)
         (local stores-requiring-removals {})
         ;; TODO: stop checking entities if we've already determined
         ;; that every component store needs to run removals
         (each [id _ (pairs entity-removals)]
           (local components-list (. entities id))
           (for [i 1 (# components-list)]
             (local component-name (. components-list i))
             (or (. stores-requiring-removals component-name)
                 (tset stores-requiring-removals component-name true)))
           (tset entities id nil))
         (each [component-name _ (pairs stores-requiring-removals)]
           (local store (. world.component-stores component-name))
           (component-store/run-removals store entity-removals))))

(local world/run-creations
       (fn [world new-entities]
         (local ids [])
         (for [i 1 (# new-entities)]
           (push ids (world/create-entity world (. new-entities i))))
         ids))

(local world/empty
       (fn [world]
         (each [_ component-store (pairs component-stores)]
           (component-store/empty component-store))
         (tset world :entities [])))

(local component-store/call-on-common-components
       (fn [fun extra-arg component-stores]
         (local num-stores (# component-stores))
         (local end-positions []) 
         (local indices [])
         (local positions [])
         (for [i 1 num-stores]
           (push indices 1)
           (push end-positions (component-store/last-component-pool-position (. component-stores i)))
           (push positions 1))

         (var done nil)
         (while (not done)
           ;; are all entity ids identical?
           (var all-identical true)
           (var entity-id nil)
           (for [i 1 num-stores]
             (local store (. component-stores i))
             (local pos (. positions i))
             (local this-id (. store.pool pos))
             (if (not entity-id) (set entity-id this-id)
                 (if (~= this-id entity-id)
                     (do
                       (set all-identical false)))))
           
           (if (and all-identical entity-id)
               (do
                 (local components [])
                 (for [i 1 num-stores]
                   (local store (. component-stores i))
                   (local index (. indices i))
                   (local pos (. positions i))
                   (push components (component-store/get-at-pool-position store pos))
                   (tset indices i (+ index 1))
                   (tset positions i (+ pos store.pool-arity)))
                 (fun extra-arg (unpack components)))

               :else
               (do
                 (var i 1)
                 (var increased-an-index false)
                 (while (not increased-an-index)
                   (do 
                     (when (~= num-stores i)
                       (do
                         (local index (. indices i))
                         (local next-index (. indices (+ i 1)))
                         (when (< index next-index)
                           (do
                             (local store (. component-stores i))
                             (local pos (. positions i))
                             (tset indices i (+ index 1))
                             (tset positions i (+ pos store.pool-arity))
                             (set increased-an-index true)))))
                     
                     ;; increase the last index if we didn't
                     ;; increase anything else
                     (when (= num-stores i)
                       (do
                         (local index (. indices i))
                         (local pos (. positions i))
                         (local store (. component-stores i))
                         (tset indices i (+ index 1))
                         (tset positions i (+ pos store.pool-arity))
                         (set increased-an-index true)))

                     (set i (+ i 1)))
                   ))) 

           ;; stop looping if we've finished all the stores
           (set done true)
           (for [i 1 num-stores]
             (when (< (. positions i) (. end-positions i))
               (set done false)))
           )))

(local world/call-on-common-components
       (fn [world component-names fun extra-arg]
         (component-store/call-on-common-components fun
                                                    extra-arg
                                                    (do (local stores [])
                                                        (for [i 0 (# component-names)]
                                                          (push stores (. world.component-stores (. component-names i))))
                                                        stores))))

{:world {:create world/create
         :create-entity world/create-entity
         :run-updates world/run-updates
         :run-removals world/run-removals
         :run-updates world/run-updates
         :run-creations world/run-creations
         :empty world/empty
         :call-on-common-components world/call-on-common-components
         }
 :component-store {:create component-store/create
                   :pool-size component-store/pool-size
                   :count component-store/count
                   :empty component-store/empty
                   :create-component component-store/create-component
                   :run-updates component-store/run-updates
                   :run-removals component-store/run-removals
                   :common-entities-3 component-store/common-entities-3
                   :call-on-common-components component-store/call-on-common-components
                   :get-at component-store/get-at
                   :last-component-pool-position component-store/last-component-pool-position
                   }
 }
