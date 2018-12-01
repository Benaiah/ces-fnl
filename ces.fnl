(local unpack (or unpack table.unpack))

;; (local inspect fennelview)

;; tail recursive push which takes a specific index, allowing it to
;; push without counting table elements or allocating tables (to
;; iterate over varargs)
(fn push-at [tab index v ...]
  (when v
    (tset tab index v)
    (local next-index (+ index 1))
    (push-at tab next-index ...)))

;; regular push calls push-at after calculating the end of the table
(fn push [tab ...]
  (local index (+ (# tab) 1))
  (push-at tab index ...))

;; this slice only supports going forward, and uses beginning + length
;; instead of beginning + end
(fn slice [tab beginning length]
  (local ret [])
  (local real-beginning (- beginning 1))
  (for [i 1 length]
    (tset ret i (. tab (+ real-beginning i))))
  ret)

(fn concat! [tab1 tab2]
  (local tab1-len (# tab1))
  (for [i 1 (# tab2)]
    (push-at tab1 (+ tab1-len i) (. tab2 i))))

(fn concat [tab1 tab2]
  (local result [])
  (local tab1-len (# tab1))
  (for [i 1 tab1-len]
    (push-at result 1 (. tab1 i)))
  (for [i 1 (# tab2)]
    (push-at result (+ tab1-len i) (. tab2 i)))
  result)

(fn get-genid [] (var x 0) (fn [] (set x (+ x 1)) x))

(fn component-store/pool-size [store] store.pool-size)

(fn component-store/count [store]
  (math.floor (/ (component-store/pool-size store) store.pool-arity)))

;; (fn component-store/view [store]
;;   (.. "#<component-store"
;;       " :name " store.name
;;       " :params " (inspect store.params)
;;       " :count " (component-store/count store)
;;       ;; " :real-count " (/ (# store.pool) store.pool-arity)
;;       ">"))

(fn component-store/create [name params]
  ;; params should be an array of argument labels
  (let [arity (# params)
        pool-arity (+ arity 1)
        name (or name "(anonymous)")]
    {:name name
     :params params
     :arity arity
     :pool-arity pool-arity
     :pool-size 0
     :pool []
     :__inspect__ component-store/view
     }))

(fn world/create [component-specs]
  (let [genid {:component (get-genid)
               :entity (get-genid)}
        world {:entities {}
               :component-stores {}
               :genid genid}]
    (each [name params (pairs component-specs)]
      (tset world.component-stores name (component-store/create name params)))
    world))

(fn component-store/last-component-pool-position [store] (+ 1 (- (component-store/pool-size store) store.pool-arity)))

(fn component-store/pool-position-from-index [store index] (+ 1 (* (- index 1) store.pool-arity)))

(fn component-store/get-id-at [store component-index]
  (let [pool-index (component-store/pool-position-from-index store component-index)]
    (. store.pool pool-index)))

(fn component-store/get-at-pool-position [store pool-index]
  (slice store.pool pool-index store.pool-arity))

(fn component-store/get-at [store component-index]
  (let [pool-index (+ 1 (* (- component-index 1) store.pool-arity))]
    (component-store/get-at-pool-position store pool-index)))

(fn component-store/get-by-id [store id]
  (var i 1)
  (var result nil)
  (var done nil)
  (while (not done)
    (local id-here (. store.pool i))
    (when (= id-here id)
      (set result (component-store/get-at-pool-position store i))
      (set done true))
    (set i (+ i store.pool-arity))
    (when (or (= id-here nil) (> id-here id))
      (set done true)))
  result)

(fn component-store/empty [store] (tset store :pool []))

(fn component-store/create-component [store args]
  (let [original-count (component-store/pool-size store)]
    (set store.pool-size (+ original-count store.pool-arity))
    (for [i 1 store.pool-arity]
      (tset store.pool (+ original-count i) (. args i)))))

(fn world/create-entity [world entity]
  (let [id (world.genid.entity)
        component-names {}
        entity-definition-count (# entity)]
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
              (tset component-names component-name true)
              (set component-store nil)
              (set component-name nil)
              (set component-args [])
              (when (> i entity-definition-count)
                (do (set done true))))))
    (tset world.entities id component-names)
    id))

(fn world/get-by-id [world entity-id]
  (local component-names (. world.entities entity-id))
  (var result [])
  (each [component-store-name _ (pairs component-names)]
    (let [component-store (. world.component-stores component-store-name)
          component-data (component-store/get-by-id component-store entity-id)
          component-data-sans-id (slice component-data 2 (- component-store.pool-arity 1))]
      (push result component-store-name (unpack component-data-sans-id))))
  result)

(fn world/get-table-by-id [world entity-id]
  (local component-names (. world.entities entity-id))
  (when component-names
    (var result {})
    (each [component-store-name _ (pairs component-names)]
      (let [component-store (. world.component-stores component-store-name)
            component-data (component-store/get-by-id component-store entity-id)
            component-data-sans-id (slice component-data 2 (- component-store.pool-arity 1))]
        (tset result component-store-name component-data-sans-id)))
    result))

(fn all [list fun]
  (var result true)
  (var done false)
  (var i 1)
  (while (and result (not done))
    (local el (. list i))
    (when (not (fun el))
      (set result false)
      (set done true))
    (set i (+ i 1)))
  result)

(fn any [list fun]
  (var result false)
  (each [i el (ipairs list)]
    (when (fun el) (set result true)))
  result)

(fn world/select-entities-with-components [world component-type-names]
  (local results [])
  (each [id entity-components (pairs world.entities)]
    (when (all component-type-names (fn [name] (. entity-components name)))
      ;; todo: use push-at and keep track of the end of the list
      ;; instead of being lazy
      (push results id)))
  results)


(fn component-store/run-updates [store entities-to-update]
  (let [pool store.pool
        pool-arity store.pool-arity
        arity store.arity]
    (for [i 1 (# pool) pool-arity]
      (local entity-update (. entities-to-update (. pool i)))
      (when entity-update
        (for [j 1 arity]
          (local val (. entity-update j))
          (when (~= val nil) (tset pool (+ i j) val)))))))

(fn component-store/run-removals [store entities-to-remove]
  (let [pool store.pool
        pool-arity store.pool-arity
        pool-size (component-store/pool-size store)
        i-of-last-id (+ 1 (- pool-size pool-arity))]

    ;; We only need to set the entity ID to nil -
    ;; since we know the arity, the compactor will
    ;; know how much to replace 
    (for [i 1 pool-size pool-arity]
      (when (. entities-to-remove (. pool i))
        (set store.pool-size (- store.pool-size pool-arity))
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
          (for [j i pool-size]
            (tset pool j nil))
          (set done true))

        (when copy-from-i
          ;; copy the next live component to this position
          (for [j 0 (- pool-arity 1)]
            (tset pool (+ i j) (. pool (+ copy-from-i j))))
          ;; set that component's entity ID to nil
          (tset pool copy-from-i nil)))
      (set i (+ i pool-arity))))
  )

(fn world/run-updates [world components-updates]
  (each [component-name component-updates (pairs components-updates)]
    (component-store/run-updates (. (. world :component-stores) component-name)
                                 component-updates)))

(fn world/run-removals [world entity-removals]
  (let [components-removals []
        entities world.entities
        stores-requiring-removals {}]
    ;; TODO: stop checking entities if we've already determined
    ;; that every component store needs to run removals
    (each [id _ (pairs entity-removals)]
      (local components-set (. entities id))
      (each [component-name _ (pairs components-set)]
        (or (. stores-requiring-removals component-name)
            (tset stores-requiring-removals component-name true)))
      (tset entities id nil))
    (each [component-name _ (pairs stores-requiring-removals)]
      (local store (. world.component-stores component-name))
      (component-store/run-removals store entity-removals))))

(fn world/run-creations [world new-entities]
  (local ids [])
  (for [i 1 (# new-entities)]
    (push ids (world/create-entity world (. new-entities i))))
  ids)

(fn world/empty [world]
  (each [_ component-store (pairs world.component-stores)]
    (component-store/empty component-store))
  (tset world :entities []))

(fn component-store/call-on-common-components [fun static-argument component-stores should-debug]
  (let [num-stores (# component-stores)
        end-indices []
        indices []
        ids []]

    ;; Init index and end position arrays
    (for [i 1 num-stores]
      (push indices 1)
      (push end-indices (+ 1 (component-store/count (. component-stores i)))))

    (var done nil)
    (var all-identical true)
    (var entity-id nil)
    (while (not done)

      ;; Check if all IDs at the selected indices are identical
      (set all-identical true)
      (set entity-id nil)
      (for [i 1 num-stores]
        (let [store (. component-stores i)
              index (. indices i)
              this-id (component-store/get-id-at store index)]
          (tset ids i this-id)
          (when (not entity-id) (set entity-id this-id))
          (when (~= this-id entity-id) (set all-identical false))
          ))

      (if
       ;; When all IDs at the selected indices are identical, retrieve
       ;; the components from the stores and call fun with their values
       ;; as tables
       (and all-identical entity-id)
       (let [components []]
         (for [i 1 num-stores]
           (let [store (. component-stores i)
                 index (. indices i)]
             (push components (component-store/get-at store index))
             (tset indices i (+ index 1))))
         (fun static-argument (unpack components)))

       ;; Otherwise, increase the first index with an ID less than the
       ;; others (this depends on the implementation behavior of
       ;; worlds and component stores, which use an incrementing ID
       ;; and always push component values into the component store as
       ;; soon as they're created).
       :else
       (do
         (var i num-stores)
         (var increased-an-index false)
         (while (not increased-an-index)
           (if (> i 1)
               (let [index (. indices i)
                     next-index (. indices (- i 1))
                     id-at-index (. ids i)
                     id-at-next-index (. ids (- i 1))]
                 (when (< id-at-index id-at-next-index)
                   (let [store (. component-stores i)]
                     (tset indices i (+ index 1))
                     (set increased-an-index true))))

               ;; increase the first index if we didn't
               ;; increase anything else
               :else
               (let [index (. indices i)
                     stores (. component-stores i)]
                 (tset indices i (+ index 1))
                 (set increased-an-index true)))
           (set i (- i 1))))) 

      ;; stop looping if we've finished any of the stores
      (for [i 1 num-stores]
        (when (and (not done) (>= (. indices i) (. end-indices i)))
          (set done true)))
      )))

(fn world/call-on-common-components [world component-names fun extra-arg]
  (component-store/call-on-common-components
   fun extra-arg
   (do (local stores [])
       (for [i 1 (# component-names)]
         (push stores (. world.component-stores (. component-names i))))
       stores)))

{:world {:create world/create
         :create-entity world/create-entity
         :get-by-id world/get-by-id
         :get-table-by-id world/get-table-by-id
         :select-entities-with-components world/select-entities-with-components
         :run-updates world/run-updates
         :run-removals world/run-removals
         :run-updates world/run-updates
         :run-creations world/run-creations
         :empty world/empty
         :call-on-common-components world/call-on-common-components
         }
 :__internal__
 {:component-store {:create component-store/create
                    :pool-size component-store/pool-size
                    :count component-store/count
                    :get-by-id component-store/get-by-id
                    :empty component-store/empty
                    :create-component component-store/create-component
                    :run-updates component-store/run-updates
                    :run-removals component-store/run-removals
                    ;; :common-entities-3 component-store/common-entities-3
                    :call-on-common-components component-store/call-on-common-components
                    :get-at component-store/get-at
                    :last-component-pool-position component-store/last-component-pool-position
                    }}}
