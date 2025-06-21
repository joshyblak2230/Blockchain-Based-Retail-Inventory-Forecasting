;; Inventory Analyst Verification Contract
;; Validates retail inventory analysts

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ANALYST_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_VERIFIED (err u102))

;; Data structures
(define-map verified-analysts principal {
    name: (string-ascii 50),
    certification-level: uint,
    verified-at: uint,
    active: bool
})

(define-map analyst-permissions principal {
    can-submit-data: bool,
    can-run-forecasts: bool,
    can-plan-replenishment: bool
})

;; Public functions
(define-public (register-analyst (analyst principal) (name (string-ascii 50)) (cert-level uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? verified-analysts analyst)) ERR_ALREADY_VERIFIED)
        (map-set verified-analysts analyst {
            name: name,
            certification-level: cert-level,
            verified-at: block-height,
            active: true
        })
        (map-set analyst-permissions analyst {
            can-submit-data: true,
            can-run-forecasts: (>= cert-level u2),
            can-plan-replenishment: (>= cert-level u3)
        })
        (ok true)
    )
)

(define-public (deactivate-analyst (analyst principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (asserts! (is-some (map-get? verified-analysts analyst)) ERR_ANALYST_NOT_FOUND)
        (map-set verified-analysts analyst
            (merge (unwrap-panic (map-get? verified-analysts analyst)) {active: false}))
        (ok true)
    )
)

;; Read-only functions
(define-read-only (is-verified-analyst (analyst principal))
    (match (map-get? verified-analysts analyst)
        analyst-data (get active analyst-data)
        false
    )
)

(define-read-only (get-analyst-permissions (analyst principal))
    (map-get? analyst-permissions analyst)
)

(define-read-only (get-analyst-info (analyst principal))
    (map-get? verified-analysts analyst)
)
