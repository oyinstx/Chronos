;; Chronos - Decentralized Time Banking System
;; A system for exchanging services and skills using time as the unit of value

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-USER-NOT-FOUND (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-SERVICE-NOT-FOUND (err u104))
(define-constant ERR-CANNOT-COMPLETE-OWN-SERVICE (err u105))
(define-constant ERR-INVALID-RATING (err u106))
(define-constant ERR-ALREADY-RATED (err u107))
(define-constant ERR-SERVICE-NOT-COMPLETED (err u108))

;; Data variables
(define-data-var next-service-id uint u1)
(define-data-var contract-owner principal tx-sender)

;; User profile structure
(define-map users principal {
    time-balance: uint,
    reputation-score: uint,
    total-services-completed: uint,
    total-services-requested: uint,
    is-active: bool,
    joined-at: uint
})

;; Service listing structure
(define-map services uint {
    provider: principal,
    requester: (optional principal),
    title: (string-ascii 100),
    description: (string-ascii 500),
    time-required: uint,
    category: (string-ascii 50),
    is-completed: bool,
    is-active: bool,
    created-at: uint,
    completed-at: (optional uint)
})

;; Rating system
(define-map service-ratings uint {
    provider-rating: (optional uint),
    requester-rating: (optional uint),
    provider-feedback: (optional (string-ascii 200)),
    requester-feedback: (optional (string-ascii 200))
})

;; Transaction history
(define-map transactions uint {
    from: principal,
    to: principal,
    amount: uint,
    service-id: (optional uint),
    transaction-type: (string-ascii 20),
    timestamp: uint
})

(define-data-var next-transaction-id uint u1)

;; Initialize new user
(define-public (register-user)
    (let ((user-exists (is-some (map-get? users tx-sender))))
        (asserts! (not user-exists) ERR-NOT-AUTHORIZED)
        (map-set users tx-sender {
            time-balance: u0,
            reputation-score: u100,
            total-services-completed: u0,
            total-services-requested: u0,
            is-active: true,
            joined-at: stacks-block-height
        })
        (ok true)))

;; Create a new service listing
(define-public (create-service (title (string-ascii 100)) (description (string-ascii 500)) (time-required uint) (category (string-ascii 50)))
    (let ((service-id (var-get next-service-id))
          (user-data (unwrap! (map-get? users tx-sender) ERR-USER-NOT-FOUND)))
        (asserts! (> time-required u0) ERR-INVALID-AMOUNT)
        (asserts! (> (len title) u0) ERR-INVALID-AMOUNT)
        (asserts! (> (len description) u0) ERR-INVALID-AMOUNT)
        (asserts! (> (len category) u0) ERR-INVALID-AMOUNT)
        (asserts! (get is-active user-data) ERR-NOT-AUTHORIZED)
        
        (map-set services service-id {
            provider: tx-sender,
            requester: none,
            title: title,
            description: description,
            time-required: time-required,
            category: category,
            is-completed: false,
            is-active: true,
            created-at: stacks-block-height,
            completed-at: none
        })
        
        (var-set next-service-id (+ service-id u1))
        (ok service-id)))

;; Request a service
(define-public (request-service (service-id uint))
    (let ((service-data (unwrap! (map-get? services service-id) ERR-SERVICE-NOT-FOUND))
          (requester-data (unwrap! (map-get? users tx-sender) ERR-USER-NOT-FOUND)))
        
        (asserts! (get is-active service-data) ERR-SERVICE-NOT-FOUND)
        (asserts! (is-none (get requester service-data)) ERR-NOT-AUTHORIZED)
        (asserts! (not (is-eq tx-sender (get provider service-data))) ERR-CANNOT-COMPLETE-OWN-SERVICE)
        (asserts! (>= (get time-balance requester-data) (get time-required service-data)) ERR-INSUFFICIENT-BALANCE)
        (asserts! (get is-active requester-data) ERR-NOT-AUTHORIZED)
        
        ;; Update service with requester
        (map-set services service-id (merge service-data {
            requester: (some tx-sender)
        }))
        
        ;; Update requester's service count
        (map-set users tx-sender (merge requester-data {
            total-services-requested: (+ (get total-services-requested requester-data) u1)
        }))
        
        (ok true)))

;; Complete a service and transfer time credits
(define-public (complete-service (service-id uint))
    (let ((service-data (unwrap! (map-get? services service-id) ERR-SERVICE-NOT-FOUND))
          (provider-data (unwrap! (map-get? users (get provider service-data)) ERR-USER-NOT-FOUND))
          (requester-principal (unwrap! (get requester service-data) ERR-NOT-AUTHORIZED))
          (requester-data (unwrap! (map-get? users requester-principal) ERR-USER-NOT-FOUND))
          (time-amount (get time-required service-data))
          (transaction-id (var-get next-transaction-id)))
        
        (asserts! (is-eq tx-sender (get provider service-data)) ERR-NOT-AUTHORIZED)
        (asserts! (not (get is-completed service-data)) ERR-NOT-AUTHORIZED)
        (asserts! (>= (get time-balance requester-data) time-amount) ERR-INSUFFICIENT-BALANCE)
        
        ;; Transfer time credits
        (map-set users requester-principal (merge requester-data {
            time-balance: (- (get time-balance requester-data) time-amount)
        }))
        
        (map-set users (get provider service-data) (merge provider-data {
            time-balance: (+ (get time-balance provider-data) time-amount),
            total-services-completed: (+ (get total-services-completed provider-data) u1)
        }))
        
        ;; Update service status
        (map-set services service-id (merge service-data {
            is-completed: true,
            is-active: false,
            completed-at: (some stacks-block-height)
        }))
        
        ;; Record transaction
        (map-set transactions transaction-id {
            from: requester-principal,
            to: (get provider service-data),
            amount: time-amount,
            service-id: (some service-id),
            transaction-type: "service-payment",
            timestamp: stacks-block-height
        })
        
        (var-set next-transaction-id (+ transaction-id u1))
        (ok true)))

;; Rate a completed service
(define-public (rate-service (service-id uint) (rating uint) (feedback (string-ascii 200)))
    (let ((service-data (unwrap! (map-get? services service-id) ERR-SERVICE-NOT-FOUND))
          (existing-rating (default-to {
              provider-rating: none,
              requester-rating: none,
              provider-feedback: none,
              requester-feedback: none
          } (map-get? service-ratings service-id)))
          (is-provider (is-eq tx-sender (get provider service-data)))
          (is-requester (is-eq tx-sender (unwrap! (get requester service-data) ERR-NOT-AUTHORIZED))))
        
        (asserts! (get is-completed service-data) ERR-SERVICE-NOT-COMPLETED)
        (asserts! (and (<= rating u5) (>= rating u1)) ERR-INVALID-RATING)
        (asserts! (or is-provider is-requester) ERR-NOT-AUTHORIZED)
        
        (if is-provider
            (begin
                (asserts! (is-none (get provider-rating existing-rating)) ERR-ALREADY-RATED)
                (map-set service-ratings service-id (merge existing-rating {
                    provider-rating: (some rating),
                    provider-feedback: (some feedback)
                }))
                (try! (update-reputation (unwrap! (get requester service-data) ERR-NOT-AUTHORIZED) rating)))
            (begin
                (asserts! (is-none (get requester-rating existing-rating)) ERR-ALREADY-RATED)
                (map-set service-ratings service-id (merge existing-rating {
                    requester-rating: (some rating),
                    requester-feedback: (some feedback)
                }))
                (try! (update-reputation (get provider service-data) rating))))
        
        (ok true)))

;; Internal function to update user reputation
(define-private (update-reputation (user principal) (new-rating uint))
    (let ((user-data (unwrap! (map-get? users user) ERR-USER-NOT-FOUND))
          (current-reputation (get reputation-score user-data))
          (total-services (+ (get total-services-completed user-data) (get total-services-requested user-data))))
        
        (if (> total-services u0)
            (let ((weighted-reputation (/ (+ (* current-reputation total-services) (* new-rating u20)) (+ total-services u1))))
                (map-set users user (merge user-data {
                    reputation-score: weighted-reputation
                }))
                (ok true))
            (ok true))))

;; Add time credits (for initial bootstrapping or earned through other means)
(define-public (add-time-credits (amount uint))
    (let ((user-data (unwrap! (map-get? users tx-sender) ERR-USER-NOT-FOUND))
          (transaction-id (var-get next-transaction-id)))
        
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        
        (map-set users tx-sender (merge user-data {
            time-balance: (+ (get time-balance user-data) amount)
        }))
        
        ;; Record transaction
        (map-set transactions transaction-id {
            from: tx-sender,
            to: tx-sender,
            amount: amount,
            service-id: none,
            transaction-type: "credit-addition",
            timestamp: stacks-block-height
        })
        
        (var-set next-transaction-id (+ transaction-id u1))
        (ok true)))

;; Read-only functions

;; Get user profile
(define-read-only (get-user (user principal))
    (map-get? users user))

;; Get service details
(define-read-only (get-service (service-id uint))
    (map-get? services service-id))

;; Get service rating
(define-read-only (get-service-rating (service-id uint))
    (map-get? service-ratings service-id))

;; Get user's time balance
(define-read-only (get-time-balance (user principal))
    (match (map-get? users user)
        user-data (ok (get time-balance user-data))
        ERR-USER-NOT-FOUND))

;; Get user's reputation score
(define-read-only (get-reputation (user principal))
    (match (map-get? users user)
        user-data (ok (get reputation-score user-data))
        ERR-USER-NOT-FOUND))

;; Check if user exists
(define-read-only (user-exists (user principal))
    (is-some (map-get? users user)))

;; Get contract owner
(define-read-only (get-contract-owner)
    (var-get contract-owner))

;; Get next service ID
(define-read-only (get-next-service-id)
    (var-get next-service-id))

;; Get transaction details
(define-read-only (get-transaction (transaction-id uint))
    (map-get? transactions transaction-id))