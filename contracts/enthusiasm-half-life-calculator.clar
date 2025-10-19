;; Enthusiasm Half-Life Calculator Contract
;; Predicts how long before "I'm totally going to get really into photography" 
;; becomes "why do I own so many lenses?"

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-hobby-not-found (err u101))
(define-constant err-invalid-enthusiasm (err u102))
(define-constant err-already-exists (err u103))
(define-constant max-enthusiasm u100)
(define-constant min-enthusiasm u1)
(define-constant base-decay-rate u2)
(define-constant prediction-threshold u10)

;; Data Variables
(define-data-var next-hobby-id uint u1)
(define-data-var total-hobbies uint u0)
(define-data-var total-abandoned uint u0)

;; Data Maps
(define-map hobbies 
    { hobby-id: uint }
    {
        name: (string-ascii 50),
        owner: principal,
        initial-enthusiasm: uint,
        current-enthusiasm: uint,
        start-date: uint,
        last-update: uint,
        decay-rate: uint,
        category: (string-ascii 30),
        equipment-count: uint,
        money-spent: uint,
        status: (string-ascii 20),
        predicted-abandonment: uint
    }
)

(define-map user-hobbies
    { user: principal }
    { hobby-ids: (list 100 uint) }
)

(define-map hobby-history
    { hobby-id: uint, entry: uint }
    {
        date: uint,
        enthusiasm: uint,
        notes: (string-ascii 200)
    }
)

;; Private Functions
(define-private (calculate-decay-rate (initial uint) (current uint) (days uint))
    (if (> days u0)
        (/ (* (- initial current) u100) (* initial days))
        u0
    )
)

(define-private (predict-abandonment (current-enthusiasm uint) (decay-rate uint))
    (if (> decay-rate u0)
        (/ (* current-enthusiasm u100) decay-rate)
        u999
    )
)

(define-private (get-enthusiasm-category (level uint))
    (if (<= level u20)
        "critical-low"
        (if (<= level u40)
            "declining"
            (if (<= level u60)
                "moderate"
                (if (<= level u80)
                    "high"
                    "obsessive"
                )
            )
        )
    )
)

;; Read-Only Functions
(define-read-only (get-hobby (hobby-id uint))
    (map-get? hobbies { hobby-id: hobby-id })
)

(define-read-only (get-user-hobbies (user principal))
    (default-to 
        { hobby-ids: (list) }
        (map-get? user-hobbies { user: user })
    )
)

(define-read-only (get-hobby-count)
    (var-get total-hobbies)
)

(define-read-only (get-abandonment-rate)
    (let ((total (var-get total-hobbies)))
        (if (> total u0)
            (/ (* (var-get total-abandoned) u100) total)
            u0
        )
    )
)

(define-read-only (get-enthusiasm-prediction (hobby-id uint))
    (match (get-hobby hobby-id)
        hobby-data (let 
            (
                (current (get current-enthusiasm hobby-data))
                (decay (get decay-rate hobby-data))
                (days-left (predict-abandonment current decay))
            )
            (ok {
                current-enthusiasm: current,
                decay-rate: decay,
                predicted-days-until-abandonment: days-left,
                enthusiasm-category: (get-enthusiasm-category current),
                abandonment-risk: (if (< days-left u30) "high" 
                                   (if (< days-left u90) "medium" "low"))
            })
        )
        (err err-hobby-not-found)
    )
)

(define-read-only (get-hobby-statistics (hobby-id uint))
    (match (get-hobby hobby-id)
        hobby-data (let
            (
                (days-active (- stacks-block-height (get start-date hobby-data)))
                (money-per-day (if (> days-active u0) (/ (get money-spent hobby-data) days-active) u0))
                (enthusiasm-loss (- (get initial-enthusiasm hobby-data) (get current-enthusiasm hobby-data)))
                (score (+ (/ (get current-enthusiasm hobby-data) u2) (if (> days-active u30) u10 u0)))
            )
            (ok {
                days-active: days-active,
                money-per-day: money-per-day,
                total-enthusiasm-loss: enthusiasm-loss,
                equipment-count: (get equipment-count hobby-data),
                hobby-score: score,
                status: (get status hobby-data)
            })
        )
        (err err-hobby-not-found)
    )
)

(define-read-only (get-contract-stats)
    (ok {
        total-hobbies: (var-get total-hobbies),
        total-abandoned: (var-get total-abandoned),
        abandonment-rate: (get-abandonment-rate),
        next-id: (var-get next-hobby-id)
    })
)

;; Public Functions
(define-public (register-hobby (name (string-ascii 50)) (initial-enthusiasm uint) (category (string-ascii 30)) (equipment-count uint) (money-spent uint))
    (let 
        (
            (hobby-id (var-get next-hobby-id))
            (current-user tx-sender)
        )
        (asserts! (and (>= initial-enthusiasm min-enthusiasm) (<= initial-enthusiasm max-enthusiasm)) (err err-invalid-enthusiasm))
        (asserts! (> (len name) u0) (err err-invalid-enthusiasm))
        
        ;; Create the hobby record
        (map-set hobbies
            { hobby-id: hobby-id }
            {
                name: name,
                owner: current-user,
                initial-enthusiasm: initial-enthusiasm,
                current-enthusiasm: initial-enthusiasm,
                start-date: stacks-block-height,
                last-update: stacks-block-height,
                decay-rate: u0,
                category: category,
                equipment-count: equipment-count,
                money-spent: money-spent,
                status: "active",
                predicted-abandonment: u999
            }
        )
        
        ;; Update user hobbies list
        (let 
            (
                (current-hobbies (get hobby-ids (get-user-hobbies current-user)))
                (updated-hobbies (unwrap! (as-max-len? (append current-hobbies hobby-id) u100) (err err-invalid-enthusiasm)))
            )
            (map-set user-hobbies 
                { user: current-user }
                { hobby-ids: updated-hobbies }
            )
        )
        
        ;; Update counters
        (var-set next-hobby-id (+ hobby-id u1))
        (var-set total-hobbies (+ (var-get total-hobbies) u1))
        
        (ok hobby-id)
    )
)

(define-public (update-enthusiasm (hobby-id uint) (new-enthusiasm uint) (notes (string-ascii 200)))
    (let 
        (
            (hobby-data (unwrap! (get-hobby hobby-id) (err err-hobby-not-found)))
            (current-user tx-sender)
        )
        (asserts! (is-eq (get owner hobby-data) current-user) (err err-owner-only))
        (asserts! (and (>= new-enthusiasm min-enthusiasm) (<= new-enthusiasm max-enthusiasm)) (err err-invalid-enthusiasm))
        
        (let
            (
                (days-passed (- stacks-block-height (get last-update hobby-data)))
                (new-decay-rate (calculate-decay-rate (get current-enthusiasm hobby-data) new-enthusiasm days-passed))
                (predicted-days (predict-abandonment new-enthusiasm new-decay-rate))
                (new-status (if (< new-enthusiasm prediction-threshold) "declining" "active"))
            )
            
            ;; Update hobby data
            (begin
                (map-set hobbies
                    { hobby-id: hobby-id }
                    (merge hobby-data {
                        current-enthusiasm: new-enthusiasm,
                        last-update: stacks-block-height,
                        decay-rate: new-decay-rate,
                        predicted-abandonment: predicted-days,
                        status: new-status
                    })
                )
                
                ;; Add history entry
                (map-set hobby-history
                    { hobby-id: hobby-id, entry: u1 }
                    {
                        date: stacks-block-height,
                        enthusiasm: new-enthusiasm,
                        notes: notes
                    }
                )
                
                ;; Update abandoned count if hobby is abandoned
                (if (is-eq new-status "declining")
                    (var-set total-abandoned (+ (var-get total-abandoned) u1))
                    true
                )
                
                (ok true)
            )
        )
    )
)

(define-public (mark-hobby-abandoned (hobby-id uint))
    (let 
        (
            (hobby-data (unwrap! (get-hobby hobby-id) (err err-hobby-not-found)))
            (current-user tx-sender)
        )
        (asserts! (is-eq (get owner hobby-data) current-user) (err err-owner-only))
        (asserts! (not (is-eq (get status hobby-data) "abandoned")) (err err-already-exists))
        
        (map-set hobbies
            { hobby-id: hobby-id }
            (merge hobby-data {
                status: "abandoned",
                current-enthusiasm: u0,
                last-update: stacks-block-height
            })
        )
        
        (var-set total-abandoned (+ (var-get total-abandoned) u1))
        (ok true)
    )
)

(define-public (add-equipment (hobby-id uint) (equipment-cost uint))
    (let 
        (
            (hobby-data (unwrap! (get-hobby hobby-id) (err err-hobby-not-found)))
            (current-user tx-sender)
        )
        (asserts! (is-eq (get owner hobby-data) current-user) (err err-owner-only))
        
        (map-set hobbies
            { hobby-id: hobby-id }
            (merge hobby-data {
                equipment-count: (+ (get equipment-count hobby-data) u1),
                money-spent: (+ (get money-spent hobby-data) equipment-cost),
                last-update: stacks-block-height
            })
        )
        (ok true)
    )
)