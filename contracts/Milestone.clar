;; title: Milestone
;; version: 1.0.0
;; summary: Learning Milestones Protocol for issuing and verifying educational badges

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_MILESTONE (err u103))
(define-constant ERR_PREREQUISITE_NOT_MET (err u104))
(define-constant ERR_INVALID_LEVEL (err u105))
(define-constant ERR_INSTRUCTOR_REQUIRED (err u106))
(define-constant ERR_STUDENT_NOT_ENROLLED (err u107))

(define-data-var next-milestone-id uint u1)
(define-data-var next-course-id uint u1)

(define-map instructors principal bool)
(define-map courses uint {
    name: (string-ascii 100),
    description: (string-ascii 500),
    instructor: principal,
    is-active: bool,
    created-at: uint
})

(define-map milestones uint {
    course-id: uint,
    name: (string-ascii 100),
    description: (string-ascii 500),
    level: uint,
    prerequisite-milestone: (optional uint),
    instructor: principal,
    points: uint,
    is-active: bool,
    created-at: uint
})

(define-map student-enrollments {student: principal, course-id: uint} {
    enrolled-at: uint,
    is-active: bool
})

(define-map student-milestones {student: principal, milestone-id: uint} {
    completed-at: uint,
    verified-by: principal,
    score: uint,
    badge-uri: (string-ascii 200)
})

(define-map student-progress principal {
    total-points: uint,
    milestones-completed: uint,
    courses-enrolled: uint,
    last-activity: uint
})

(define-map milestone-completions uint uint)

(define-map course-leaderboard {course-id: uint, student: principal} {
    course-points: uint,
    course-milestones: uint,
    last-updated: uint
})

(define-map course-top-students uint (list 10 principal))

(define-read-only (get-contract-owner)
    CONTRACT_OWNER
)

(define-read-only (is-instructor (user principal))
    (default-to false (map-get? instructors user))
)

(define-read-only (get-course (course-id uint))
    (map-get? courses course-id)
)

(define-read-only (get-milestone (milestone-id uint))
    (map-get? milestones milestone-id)
)

(define-read-only (get-student-enrollment (student principal) (course-id uint))
    (map-get? student-enrollments {student: student, course-id: course-id})
)

(define-read-only (get-student-milestone (student principal) (milestone-id uint))
    (map-get? student-milestones {student: student, milestone-id: milestone-id})
)

(define-read-only (get-student-progress (student principal))
    (default-to {total-points: u0, milestones-completed: u0, courses-enrolled: u0, last-activity: u0}
        (map-get? student-progress student))
)

(define-read-only (get-milestone-completions (milestone-id uint))
    (default-to u0 (map-get? milestone-completions milestone-id))
)

(define-read-only (has-completed-milestone (student principal) (milestone-id uint))
    (is-some (map-get? student-milestones {student: student, milestone-id: milestone-id}))
)

(define-read-only (check-prerequisite (student principal) (milestone-id uint))
    (match (get-milestone milestone-id)
        milestone-data
        (match (get prerequisite-milestone milestone-data)
            prereq-id (has-completed-milestone student prereq-id)
            true
        )
        false
    )
)

(define-read-only (is-student-enrolled (student principal) (course-id uint))
    (match (get-student-enrollment student course-id)
        enrollment (get is-active enrollment)
        false
    )
)

(define-read-only (get-next-milestone-id)
    (var-get next-milestone-id)
)

(define-read-only (get-next-course-id)
    (var-get next-course-id)
)

(define-read-only (get-course-leaderboard-entry (course-id uint) (student principal))
    (map-get? course-leaderboard {course-id: course-id, student: student})
)

(define-read-only (get-student-course-rank (course-id uint) (student principal))
    (match (get-course-leaderboard-entry course-id student)
        student-data
        (let
            (
                (student-points (get course-points student-data))
                (top-students (default-to (list) (map-get? course-top-students course-id)))
            )
            (ok {
                rank: (+ u1 (len (filter is-higher-ranked top-students))),
                points: student-points,
                milestones: (get course-milestones student-data)
            })
        )
        ERR_NOT_FOUND
    )
)

(define-read-only (get-course-top-performers (course-id uint))
    (default-to (list) (map-get? course-top-students course-id))
)

(define-private (is-higher-ranked (other-student principal))
    (> (default-to u0 (get course-points (get-course-leaderboard-entry u0 other-student))) u0)
)

(define-private (update-course-leaderboard (student principal) (course-id uint) (points uint) (current-height uint))
    (let
        (
            (current-entry (default-to {course-points: u0, course-milestones: u0, last-updated: u0}
                (get-course-leaderboard-entry course-id student)))
            (new-points (+ (get course-points current-entry) points))
            (new-milestones (+ (get course-milestones current-entry) u1))
        )
        (map-set course-leaderboard {course-id: course-id, student: student} {
            course-points: new-points,
            course-milestones: new-milestones,
            last-updated: current-height
        })
        (update-top-students course-id student new-points)
    )
)

(define-private (update-top-students (course-id uint) (student principal) (student-points uint))
    (let
        (
            (current-top (default-to (list) (map-get? course-top-students course-id)))
        )
        (if (or (< (len current-top) u10) (should-be-in-top student student-points current-top))
            (map-set course-top-students course-id (add-to-top-list student current-top student-points))
            true
        )
    )
)

(define-private (should-be-in-top (student principal) (points uint) (top-list (list 10 principal)))
    (if (< (len top-list) u10)
        true
        (let
            (
                (lowest-in-top (get-lowest-points-in-list top-list))
            )
            (> points lowest-in-top)
        )
    )
)

(define-private (get-lowest-points-in-list (top-list (list 10 principal)))
    (fold min-points-reducer top-list u999999999)
)

(define-private (min-points-reducer (student principal) (current-min uint))
    (let
        (
            (student-entry (get-course-leaderboard-entry u0 student))
        )
        (match student-entry
            entry (let ((pts (get course-points entry))) (if (< pts current-min) pts current-min))
            current-min
        )
    )
)

(define-private (add-to-top-list (student principal) (current-list (list 10 principal)) (points uint))
    (let
        (
            (filtered-list (filter not-this-student current-list))
            (new-list (unwrap-panic (as-max-len? (append filtered-list student) u10)))
        )
        (if (<= (len new-list) u10)
            new-list
            (take-top-10 new-list)
        )
    )
)

(define-private (not-this-student (other principal))
    (not (is-eq other tx-sender))
)

(define-private (take-top-10 (full-list (list 10 principal)))
    (let
        (
            (list-length (len full-list))
        )
        (if (> list-length u10)
            (unwrap-panic (as-max-len? (list) u10))
            full-list
        )
    )
)

(define-public (add-instructor (new-instructor principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (ok (map-set instructors new-instructor true))
    )
)

(define-public (remove-instructor (instructor principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (ok (map-delete instructors instructor))
    )
)

(define-public (create-course (name (string-ascii 100)) (description (string-ascii 500)))
    (let
        (
            (course-id (var-get next-course-id))
            (current-height u0)
        )
        (asserts! (is-instructor tx-sender) ERR_INSTRUCTOR_REQUIRED)
        (map-set courses course-id {
            name: name,
            description: description,
            instructor: tx-sender,
            is-active: true,
            created-at: current-height
        })
        (var-set next-course-id (+ course-id u1))
        (ok course-id)
    )
)

(define-public (deactivate-course (course-id uint))
    (match (get-course course-id)
        course-data
        (begin
            (asserts! (or (is-eq tx-sender (get instructor course-data)) (is-eq tx-sender CONTRACT_OWNER)) ERR_UNAUTHORIZED)
            (ok (map-set courses course-id (merge course-data {is-active: false})))
        )
        ERR_NOT_FOUND
    )
)

(define-public (enroll-student (student principal) (course-id uint))
    (let
        (
            (current-height u0)
        )
        (asserts! (is-instructor tx-sender) ERR_INSTRUCTOR_REQUIRED)
        (asserts! (is-some (get-course course-id)) ERR_NOT_FOUND)
        (asserts! (is-none (get-student-enrollment student course-id)) ERR_ALREADY_EXISTS)
        (map-set student-enrollments {student: student, course-id: course-id} {
            enrolled-at: current-height,
            is-active: true
        })
        (let
            (
                (current-progress (get-student-progress student))
            )
            (map-set student-progress student (merge current-progress {
                courses-enrolled: (+ (get courses-enrolled current-progress) u1),
                last-activity: current-height
            }))
        )
        (ok true)
    )
)

(define-public (create-milestone 
    (course-id uint) 
    (name (string-ascii 100)) 
    (description (string-ascii 500)) 
    (level uint) 
    (prerequisite-milestone (optional uint)) 
    (points uint))
    (let
        (
            (milestone-id (var-get next-milestone-id))
            (current-height u0)
        )
        (asserts! (is-instructor tx-sender) ERR_INSTRUCTOR_REQUIRED)
        (asserts! (is-some (get-course course-id)) ERR_NOT_FOUND)
        (asserts! (and (>= level u1) (<= level u10)) ERR_INVALID_LEVEL)
        (match prerequisite-milestone
            prereq-id (asserts! (is-some (get-milestone prereq-id)) ERR_NOT_FOUND)
            true
        )
        (map-set milestones milestone-id {
            course-id: course-id,
            name: name,
            description: description,
            level: level,
            prerequisite-milestone: prerequisite-milestone,
            instructor: tx-sender,
            points: points,
            is-active: true,
            created-at: current-height
        })
        (var-set next-milestone-id (+ milestone-id u1))
        (ok milestone-id)
    )
)

(define-public (complete-milestone (student principal) (milestone-id uint) (score uint) (badge-uri (string-ascii 200)))
    (let
        (
            (current-height u0)
        )
        (asserts! (is-instructor tx-sender) ERR_INSTRUCTOR_REQUIRED)
        (match (get-milestone milestone-id)
            milestone-data
            (begin
                (asserts! (is-student-enrolled student (get course-id milestone-data)) ERR_STUDENT_NOT_ENROLLED)
                (asserts! (check-prerequisite student milestone-id) ERR_PREREQUISITE_NOT_MET)
                (asserts! (is-none (get-student-milestone student milestone-id)) ERR_ALREADY_EXISTS)
                (asserts! (<= score u100) ERR_INVALID_MILESTONE)
                (map-set student-milestones {student: student, milestone-id: milestone-id} {
                    completed-at: current-height,
                    verified-by: tx-sender,
                    score: score,
                    badge-uri: badge-uri
                })
                (map-set milestone-completions milestone-id 
                    (+ (get-milestone-completions milestone-id) u1))
                (let
                    (
                        (current-progress (get-student-progress student))
                        (milestone-points (get points milestone-data))
                        (course-id (get course-id milestone-data))
                    )
                    (map-set student-progress student (merge current-progress {
                        total-points: (+ (get total-points current-progress) milestone-points),
                        milestones-completed: (+ (get milestones-completed current-progress) u1),
                        last-activity: current-height
                    }))
                    (update-course-leaderboard student course-id milestone-points current-height)
                )
                (ok true)
            )
            ERR_NOT_FOUND
        )
    )
)

(define-public (revoke-milestone (student principal) (milestone-id uint))
    (match (get-milestone milestone-id)
        milestone-data
        (begin
            (asserts! (or (is-eq tx-sender (get instructor milestone-data)) (is-eq tx-sender CONTRACT_OWNER)) ERR_UNAUTHORIZED)
            (match (get-student-milestone student milestone-id)
                completion-data
                (begin
                    (map-delete student-milestones {student: student, milestone-id: milestone-id})
                    (map-set milestone-completions milestone-id 
                        (- (get-milestone-completions milestone-id) u1))
                    (let
                        (
                            (current-progress (get-student-progress student))
                            (milestone-points (get points milestone-data))
                        )
                        (map-set student-progress student (merge current-progress {
                            total-points: (- (get total-points current-progress) milestone-points),
                            milestones-completed: (- (get milestones-completed current-progress) u1),
                            last-activity: u0
                        }))
                    )
                    (ok true)
                )
                ERR_NOT_FOUND
            )
        )
        ERR_NOT_FOUND
    )
)

(define-public (deactivate-milestone (milestone-id uint))
    (match (get-milestone milestone-id)
        milestone-data
        (begin
            (asserts! (or (is-eq tx-sender (get instructor milestone-data)) (is-eq tx-sender CONTRACT_OWNER)) ERR_UNAUTHORIZED)
            (ok (map-set milestones milestone-id (merge milestone-data {is-active: false})))
        )
        ERR_NOT_FOUND
    )
)
