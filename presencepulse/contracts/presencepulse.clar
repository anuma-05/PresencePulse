;; PresencePulse: Digital Footprints Protocol
;; A blockchain-based attendance verification system with Enhanced Features

;; Constants
(define-constant admin-address tx-sender)
(define-constant error-admin-only (err u100))
(define-constant error-duplicate-attendance (err u101))
(define-constant error-gathering-not-found (err u102))
(define-constant error-ineligible (err u103))
(define-constant error-invalid-gathering-id (err u104))
(define-constant error-invalid-date (err u105))
(define-constant error-invalid-capacity (err u106))
(define-constant error-invalid-title (err u107))
(define-constant error-gathering-ended (err u108))
(define-constant error-insufficient-funds (err u109))
(define-constant error-transfer-failed (err u110))
(define-constant error-already-verified (err u111))
(define-constant error-invalid-role (err u112))
(define-constant error-gathering-cancelled (err u113))
(define-constant error-mint-failed (err u114))
(define-constant error-invalid-fee (err u115))
(define-constant error-invalid-description (err u116))
(define-constant error-invalid-gathering-type (err u117))
(define-constant error-invalid-location (err u118))
(define-constant error-invalid-verification-method (err u119))
(define-constant error-invalid-attendee (err u120))
(define-constant error-invalid-facilitator (err u121))
(define-constant error-invalid-is-private (err u122))

;; Data Variables
(define-data-var next-gathering-id uint u0)
(define-data-var total-gatherings-created uint u0)
(define-data-var platform-fee uint u100)

;; Enhanced Data Maps
(define-map gatherings 
  { gathering-id: uint }
  {
    title: (string-ascii 50),
    scheduled-time: uint,
    capacity: uint,
    attendee-count: uint,
    creator: principal,
    entry-fee: uint,
    is-private: bool,
    is-cancelled: bool,
    description: (string-ascii 500),
    gathering-type: (string-ascii 20),
    location: (optional (string-ascii 100))
  }
)

(define-map attendances
  { gathering-id: uint, attendee: principal }
  {
    verified: bool,
    block-time: uint,
    validation-status: bool,
    verification-method: (string-ascii 20),
    attendance-duration: uint
  }
)

(define-map attendee-profile
  { attendee: principal }
  {
    gatherings-attended: uint,
    points-earned: uint,
    reputation-score: uint,
    roles: (list 10 (string-ascii 20)),
    last-active: uint
  }
)

(define-map gathering-facilitators
  { gathering-id: uint }
  { facilitators: (list 5 principal) }
)

(define-map whitelisted-attendees
  { gathering-id: uint }
  { attendees: (list 100 principal) }
)

;; NFT Definitions
(define-non-fungible-token pulse-token uint)

;; Private Functions
(define-private (is-admin)
  (is-eq tx-sender admin-address)
)

(define-private (is-valid-title (title (string-ascii 50)))
  (and
    (> (len title) u0)
    (<= (len title) u50)
  )
)

(define-private (is-valid-description (description (string-ascii 500)))
  (and
    (> (len description) u0)
    (<= (len description) u500)
  )
)

(define-private (is-valid-gathering-type (gathering-type (string-ascii 20)))
  (and
    (> (len gathering-type) u0)
    (<= (len gathering-type) u20)
  )
)

(define-private (is-valid-location (location (optional (string-ascii 100))))
  (match location
    loc (and (> (len loc) u0) (<= (len loc) u100))
    true
  )
)

(define-private (is-valid-fee (fee uint))
  (<= fee u1000000000)
)

(define-private (is-future-date (date uint))
  (> date block-height)
)

(define-private (is-valid-capacity (capacity uint))
  (and
    (> capacity u0)
    (<= capacity u1000)
  )
)

(define-private (is-valid-verification-method (method (string-ascii 20)))
  (and
    (> (len method) u0)
    (<= (len method) u20)
  )
)

(define-private (increment-gathering-id)
  (let ((current (var-get next-gathering-id)))
    (var-set next-gathering-id (+ current u1))
    current
  )
)

(define-private (is-gathering-facilitator (gathering-id uint) (user principal))
  (let ((facilitators (default-to { facilitators: (list) } (map-get? gathering-facilitators { gathering-id: gathering-id }))))
    (is-some (index-of (get facilitators facilitators) user))
  )
)

(define-private (update-reputation (user principal) (points uint))
  (let ((profile (default-to 
                { gatherings-attended: u0, points-earned: u0, reputation-score: u0, roles: (list), last-active: u0 }
                (map-get? attendee-profile { attendee: user }))))
    (map-set attendee-profile { attendee: user }
      (merge profile {
        reputation-score: (+ (get reputation-score profile) points)
      })
    )
    true
  )
)

(define-private (decrease-reputation (user principal) (points uint))
  (let ((profile (default-to 
                { gatherings-attended: u0, points-earned: u0, reputation-score: u0, roles: (list), last-active: u0 }
                (map-get? attendee-profile { attendee: user }))))
    (map-set attendee-profile { attendee: user }
      (merge profile {
        reputation-score: (if (> (get reputation-score profile) points)
                            (- (get reputation-score profile) points)
                            u0)
      })
    )
    true
  )
)

(define-private (issue-token (gathering-id uint) (recipient principal))
  (nft-mint? pulse-token gathering-id recipient)
)

(define-private (process-attendance-record (gathering-id uint) (gathering { title: (string-ascii 50),
    scheduled-time: uint,
    capacity: uint,
    attendee-count: uint,
    creator: principal,
    entry-fee: uint,
    is-private: bool,
    is-cancelled: bool,
    description: (string-ascii 500),
    gathering-type: (string-ascii 20),
    location: (optional (string-ascii 100)) }))
  (begin
    (asserts! (is-valid-gathering-id gathering-id) error-invalid-gathering-id)
    (asserts! (is-valid-fee (get entry-fee gathering)) error-invalid-fee)
    
    (if (> (get entry-fee gathering) u0)
        (begin
          (try! (stx-transfer? (get entry-fee gathering) tx-sender (get creator gathering)))
          (try! (stx-transfer? (var-get platform-fee) tx-sender admin-address)))
        true)
    
    (map-set gatherings { gathering-id: gathering-id }
      (merge gathering { attendee-count: (+ (get attendee-count gathering) u1) }))
    
    (map-set attendances { gathering-id: gathering-id, attendee: tx-sender }
      {
        verified: true,
        block-time: block-height,
        validation-status: false,
        verification-method: "",
        attendance-duration: u0
      })
    
    (try! (issue-token gathering-id tx-sender))
    (ok true)
  )
)

(define-private (is-valid-gathering-id (gathering-id uint))
  (< gathering-id (var-get next-gathering-id))
)

(define-private (is-valid-is-private (is-private bool))
  (or (is-eq is-private true) (is-eq is-private false))
)

;; Public Functions
(define-public (register-gathering (title (string-ascii 50)) 
                           (scheduled-time uint) 
                           (capacity uint)
                           (entry-fee uint)
                           (is-private bool)
                           (description (string-ascii 500))
                           (gathering-type (string-ascii 20))
                           (location (optional (string-ascii 100))))
  (begin
    (asserts! (is-admin) error-admin-only)
    (asserts! (is-valid-title title) error-invalid-title)
    (asserts! (is-future-date scheduled-time) error-invalid-date)
    (asserts! (is-valid-capacity capacity) error-invalid-capacity)
    (asserts! (is-valid-fee entry-fee) error-invalid-fee)
    (asserts! (is-valid-description description) error-invalid-description)
    (asserts! (is-valid-gathering-type gathering-type) error-invalid-gathering-type)
    (asserts! (is-valid-location location) error-invalid-location)
    (asserts! (is-valid-is-private is-private) error-invalid-is-private)
    
    (let ((gathering-id (increment-gathering-id)))
      (map-set gatherings { gathering-id: gathering-id }
        {
          title: title,
          scheduled-time: scheduled-time,
          capacity: capacity,
          attendee-count: u0,
          creator: tx-sender,
          entry-fee: entry-fee,
          is-private: is-private,
          is-cancelled: false,
          description: description,
          gathering-type: gathering-type,
          location: location
        })
      
      (var-set total-gatherings-created (+ (var-get total-gatherings-created) u1))
      (ok gathering-id))
  )
)

(define-public (record-attendance (gathering-id uint))
  (begin
    (asserts! (is-valid-gathering-id gathering-id) error-invalid-gathering-id)
    (let ((gathering (unwrap! (map-get? gatherings { gathering-id: gathering-id }) error-gathering-not-found)))
      (begin
        (asserts! (not (get is-cancelled gathering)) error-gathering-cancelled)
        (asserts! (< (get attendee-count gathering) (get capacity gathering)) error-ineligible)
        (asserts! (is-none (map-get? attendances { gathering-id: gathering-id, attendee: tx-sender })) error-duplicate-attendance)
        (asserts! (or (not (get is-private gathering))
                     (is-some (index-of (get attendees (default-to { attendees: (list) }
                       (map-get? whitelisted-attendees { gathering-id: gathering-id }))) tx-sender)))
                error-ineligible)
        
        (process-attendance-record gathering-id gathering)))
  )
)

(define-public (validate-attendance (gathering-id uint) (attendee principal) (verification-method (string-ascii 20)))
  (begin
    (asserts! (is-valid-gathering-id gathering-id) error-invalid-gathering-id)
    (asserts! (is-valid-verification-method verification-method) error-invalid-verification-method)
    (asserts! (not (is-eq attendee tx-sender)) error-invalid-attendee)
    (let ((attendance-record (unwrap! (map-get? attendances { gathering-id: gathering-id, attendee: attendee }) error-ineligible)))
      (begin
        (asserts! (or (is-admin) (is-gathering-facilitator gathering-id tx-sender)) error-admin-only)
        (asserts! (not (get validation-status attendance-record)) error-already-verified)
        
        (map-set attendances { gathering-id: gathering-id, attendee: attendee }
          (merge attendance-record {
            validation-status: true,
            verification-method: verification-method
          }))
        
        (as-contract (update-reputation attendee u10))
        (ok true)))
  )
)

(define-public (cancel-gathering (gathering-id uint))
  (begin
    (asserts! (is-valid-gathering-id gathering-id) error-invalid-gathering-id)
    (let ((gathering (unwrap! (map-get? gatherings { gathering-id: gathering-id }) error-gathering-not-found)))
      (begin
        (asserts! (or (is-admin) (is-eq (get creator gathering) tx-sender)) error-admin-only)
        (asserts! (not (get is-cancelled gathering)) error-gathering-cancelled)
        
        (map-set gatherings { gathering-id: gathering-id }
          (merge gathering { is-cancelled: true }))
        (ok true)))
  )
)

(define-public (add-facilitator (gathering-id uint) (facilitator principal))
  (begin
    (asserts! (is-valid-gathering-id gathering-id) error-invalid-gathering-id)
    (asserts! (not (is-eq facilitator tx-sender)) error-invalid-facilitator)
    (let ((gathering (unwrap! (map-get? gatherings { gathering-id: gathering-id }) error-gathering-not-found))
          (current-facilitators (default-to { facilitators: (list) } (map-get? gathering-facilitators { gathering-id: gathering-id }))))
      (begin
        (asserts! (or (is-admin) (is-eq (get creator gathering) tx-sender)) error-admin-only)
        (asserts! (< (len (get facilitators current-facilitators)) u5) error-ineligible)
        (asserts! (is-none (index-of (get facilitators current-facilitators) facilitator)) error-invalid-facilitator)
        
        (let ((new-facilitators (unwrap! (as-max-len? (append (get facilitators current-facilitators) facilitator) u5)
                                       error-ineligible)))
          (map-set gathering-facilitators { gathering-id: gathering-id }
            { facilitators: new-facilitators })
          (ok true))))
  )
)

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-admin) error-admin-only)
    (asserts! (is-valid-fee new-fee) error-invalid-fee)
    (var-set platform-fee new-fee)
    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-gathering (gathering-id uint))
  (map-get? gatherings { gathering-id: gathering-id })
)

(define-read-only (get-attendance-record (gathering-id uint) (attendee principal))
  (map-get? attendances { gathering-id: gathering-id, attendee: attendee })
)

(define-read-only (get-attendee-profile (attendee principal))
  (default-to 
    { gatherings-attended: u0, points-earned: u0, reputation-score: u0, roles: (list), last-active: u0 }
    (map-get? attendee-profile { attendee: attendee })
  )
)

(define-read-only (get-total-gatherings)
  (var-get total-gatherings-created)
)

(define-read-only (is-whitelisted (gathering-id uint) (attendee principal))
  (let ((whitelist (default-to { attendees: (list) } (map-get? whitelisted-attendees { gathering-id: gathering-id }))))
    (is-some (index-of (get attendees whitelist) attendee))
  )
)
