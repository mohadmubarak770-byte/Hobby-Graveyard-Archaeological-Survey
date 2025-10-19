;; Starter Kit Depreciation Tracker Contract
;; Values the resale potential of barely-used hobby equipment 
;; gathering dust in increasingly creative storage locations

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-item-not-found (err u201))
(define-constant err-invalid-price (err u202))
(define-constant err-invalid-condition (err u203))
(define-constant err-already-exists (err u204))
(define-constant max-condition-score u10)
(define-constant min-condition-score u1)
(define-constant max-storage-creativity u100)
(define-constant base-depreciation-rate u15)
(define-constant usage-bonus-threshold u50)

;; Data Variables
(define-data-var next-item-id uint u1)
(define-data-var total-equipment uint u0)
(define-data-var total-value-lost uint u0)
(define-data-var most-creative-storage uint u0)

;; Data Maps
(define-map equipment-items
    { item-id: uint }
    {
        name: (string-ascii 100),
        owner: principal,
        hobby-category: (string-ascii 50),
        purchase-price: uint,
        purchase-date: uint,
        current-condition: uint,
        usage-frequency: uint,
        storage-location: (string-ascii 100),
        storage-creativity-score: uint,
        last-used: uint,
        depreciation-rate: uint,
        estimated-resale-value: uint,
        still-in-box: bool,
        regret-level: uint
    }
)

(define-map user-equipment
    { user: principal }
    { equipment-ids: (list 200 uint) }
)

(define-map equipment-history
    { item-id: uint, entry: uint }
    {
        date: uint,
        condition: uint,
        usage-count: uint,
        storage-change: (string-ascii 100),
        notes: (string-ascii 200)
    }
)

(define-map storage-locations
    { location: (string-ascii 100) }
    {
        creativity-score: uint,
        frequency: uint,
        user-count: uint
    }
)

;; Private Functions
(define-private (calculate-depreciation (purchase-price uint) (days-owned uint) (condition uint) (usage-frequency uint))
    (let
        (
            (base-rate (/ (* purchase-price base-depreciation-rate) u100))
            (time-factor (/ (* days-owned base-rate) u365))
            (condition-factor (/ (* purchase-price (- max-condition-score condition)) u100))
            (usage-bonus (if (> usage-frequency usage-bonus-threshold) u0 (/ purchase-price u20)))
        )
        (+ time-factor condition-factor usage-bonus)
    )
)

(define-private (calculate-resale-value (purchase-price uint) (depreciation uint))
    (if (> depreciation purchase-price)
        u0
        (- purchase-price depreciation)
    )
)

(define-private (assess-storage-creativity (location (string-ascii 100)))
    (if (is-eq location "garage") u10
        (if (is-eq location "closet") u20
            (if (is-eq location "attic") u40
                (if (is-eq location "under-bed") u60
                    (if (is-eq location "basement-corner") u70
                        (if (is-eq location "shed-behind-lawnmower") u90
                            u100
                        )
                    )
                )
            )
        )
    )
)

(define-private (calculate-regret-level (purchase-price uint) (usage-frequency uint) (days-since-last-use uint))
    (let
        (
            (price-regret (/ purchase-price u100))
            (usage-regret (if (< usage-frequency u10) u30 u0))
            (time-regret (if (> days-since-last-use u90) u40 u0))
        )
        (+ price-regret usage-regret time-regret)
    )
)

(define-private (get-condition-description (condition uint))
    (if (<= condition u2)
        "barely-functional"
        (if (<= condition u4)
            "showing-wear"
            (if (<= condition u6)
                "good-condition"
                (if (<= condition u8)
                    "like-new"
                    "mint-in-box"
                )
            )
        )
    )
)

;; Read-Only Functions
(define-read-only (get-equipment-item (item-id uint))
    (map-get? equipment-items { item-id: item-id })
)

(define-read-only (get-user-equipment (user principal))
    (default-to
        { equipment-ids: (list) }
        (map-get? user-equipment { user: user })
    )
)

(define-read-only (get-total-equipment-count)
    (var-get total-equipment)
)

(define-read-only (get-total-value-lost)
    (var-get total-value-lost)
)

(define-read-only (get-equipment-valuation (item-id uint))
    (match (get-equipment-item item-id)
        item-data (let
            (
                (days-owned (- stacks-block-height (get purchase-date item-data)))
                (days-since-use (- stacks-block-height (get last-used item-data)))
                (depreciation (calculate-depreciation 
                    (get purchase-price item-data)
                    days-owned
                    (get current-condition item-data)
                    (get usage-frequency item-data)
                ))
                (resale-value (calculate-resale-value (get purchase-price item-data) depreciation))
                (regret (calculate-regret-level 
                    (get purchase-price item-data) 
                    (get usage-frequency item-data) 
                    days-since-use
                ))
            )
            (ok {
                original-price: (get purchase-price item-data),
                current-value: resale-value,
                total-depreciation: depreciation,
                depreciation-rate: (/ (* depreciation u100) (get purchase-price item-data)),
                days-owned: days-owned,
                days-since-last-use: days-since-use,
                condition-description: (get-condition-description (get current-condition item-data)),
                storage-creativity: (get storage-creativity-score item-data),
                regret-level: regret,
                still-in-original-packaging: (get still-in-box item-data)
            })
        )
        (err err-item-not-found)
    )
)

(define-read-only (get-storage-creativity-ranking)
    (ok {
        most-creative-storage: (var-get most-creative-storage),
        creativity-categories: {
            basic: "garage, closet (0-30)",
            intermediate: "attic, under-bed (31-60)",
            advanced: "basement-corner, shed (61-90)",
            expert: "custom-locations (91-100)"
        }
    })
)

(define-read-only (get-user-portfolio-summary (user principal))
    (let
        (
            (user-items (get equipment-ids (get-user-equipment user)))
        )
        (ok {
            total-items: (len user-items),
            equipment-list: user-items
        })
    )
)

(define-read-only (get-contract-overview)
    (ok {
        total-equipment: (var-get total-equipment),
        total-value-lost: (var-get total-value-lost),
        most-creative-storage: (var-get most-creative-storage),
        next-item-id: (var-get next-item-id)
    })
)

;; Public Functions
(define-public (add-equipment (name (string-ascii 100)) (hobby-category (string-ascii 50)) (purchase-price uint) (purchase-date uint) (storage-location (string-ascii 100)))
    (let
        (
            (item-id (var-get next-item-id))
            (current-user tx-sender)
            (creativity-score (assess-storage-creativity storage-location))
        )
        (asserts! (> purchase-price u0) (err err-invalid-price))
        (asserts! (> (len name) u0) (err err-invalid-price))
        (asserts! (<= purchase-date stacks-block-height) (err err-invalid-price))
        
        ;; Create equipment record
        (map-set equipment-items
            { item-id: item-id }
            {
                name: name,
                owner: current-user,
                hobby-category: hobby-category,
                purchase-price: purchase-price,
                purchase-date: purchase-date,
                current-condition: max-condition-score,
                usage-frequency: u0,
                storage-location: storage-location,
                storage-creativity-score: creativity-score,
                last-used: purchase-date,
                depreciation-rate: u0,
                estimated-resale-value: purchase-price,
                still-in-box: true,
                regret-level: u0
            }
        )
        
        ;; Update user equipment list
        (let
            (
                (current-items (get equipment-ids (get-user-equipment current-user)))
                (updated-items (unwrap! (as-max-len? (append current-items item-id) u200) (err err-invalid-price)))
            )
            (map-set user-equipment
                { user: current-user }
                { equipment-ids: updated-items }
            )
        )
        
        ;; Update storage location stats
        (let
            (
                (location-stats (default-to { creativity-score: u0, frequency: u0, user-count: u0 } 
                                (map-get? storage-locations { location: storage-location })))
            )
            (map-set storage-locations
                { location: storage-location }
                {
                    creativity-score: creativity-score,
                    frequency: (+ (get frequency location-stats) u1),
                    user-count: (+ (get user-count location-stats) u1)
                }
            )
        )
        
        ;; Update global stats
        (var-set next-item-id (+ item-id u1))
        (var-set total-equipment (+ (var-get total-equipment) u1))
        (begin
            (if (> creativity-score (var-get most-creative-storage))
                (var-set most-creative-storage creativity-score)
                true
            )
            (ok item-id)
        )
    )
)

(define-public (update-condition-and-usage (item-id uint) (new-condition uint) (usage-increment uint) (notes (string-ascii 200)))
    (let
        (
            (item-data (unwrap! (get-equipment-item item-id) (err err-item-not-found)))
            (current-user tx-sender)
        )
        (asserts! (is-eq (get owner item-data) current-user) (err err-owner-only))
        (asserts! (and (>= new-condition min-condition-score) (<= new-condition max-condition-score)) (err err-invalid-condition))
        
        (let
            (
                (days-owned (- stacks-block-height (get purchase-date item-data)))
                (new-usage (+ (get usage-frequency item-data) usage-increment))
                (depreciation (calculate-depreciation
                    (get purchase-price item-data)
                    days-owned
                    new-condition
                    new-usage
                ))
                (resale-value (calculate-resale-value (get purchase-price item-data) depreciation))
                (new-regret (calculate-regret-level 
                    (get purchase-price item-data) 
                    new-usage 
                    (- stacks-block-height (get last-used item-data))
                ))
            )
            
            ;; Update equipment data
            (map-set equipment-items
                { item-id: item-id }
                (merge item-data {
                    current-condition: new-condition,
                    usage-frequency: new-usage,
                    last-used: (if (> usage-increment u0) stacks-block-height (get last-used item-data)),
                    depreciation-rate: (/ (* depreciation u100) (get purchase-price item-data)),
                    estimated-resale-value: resale-value,
                    still-in-box: (and (get still-in-box item-data) (is-eq usage-increment u0)),
                    regret-level: new-regret
                })
            )
            
            ;; Add history entry
            (map-set equipment-history
                { item-id: item-id, entry: u1 }
                {
                    date: stacks-block-height,
                    condition: new-condition,
                    usage-count: new-usage,
                    storage-change: "condition-update",
                    notes: notes
                }
            )
            
            ;; Update global value lost
            (let
                (
                    (value-lost (- (get purchase-price item-data) resale-value))
                )
                (var-set total-value-lost (+ (var-get total-value-lost) value-lost))
            )
        )
        (ok true)
    )
)

(define-public (relocate-storage (item-id uint) (new-location (string-ascii 100)))
    (let
        (
            (item-data (unwrap! (get-equipment-item item-id) (err err-item-not-found)))
            (current-user tx-sender)
            (new-creativity (assess-storage-creativity new-location))
        )
        (asserts! (is-eq (get owner item-data) current-user) (err err-owner-only))
        
        ;; Update item storage
        (map-set equipment-items
            { item-id: item-id }
            (merge item-data {
                storage-location: new-location,
                storage-creativity-score: new-creativity
            })
        )
        
        ;; Update global creativity record
        (begin
            (if (> new-creativity (var-get most-creative-storage))
                (var-set most-creative-storage new-creativity)
                true
            )
            (ok true)
        )
    )
)