# 🎓 Learning Milestones Protocol

A blockchain-based system for issuing and verifying educational badges and tokens as students complete learning milestones.

## 📋 Overview

The Learning Milestones Protocol enables educational institutions to create verifiable, on-chain records of student achievements. Students earn badges for completing milestones within courses, creating an immutable record of their educational progress.

## ✨ Features

- 👨‍🏫 **Instructor Management** - Add/remove authorized instructors
- 📚 **Course Creation** - Create and manage educational courses
- 🎯 **Milestone System** - Define achievement milestones with prerequisites
- 🎖️ **Badge Issuance** - Award verifiable badges for completions
- 📊 **Progress Tracking** - Track student progress and total points
- 🔐 **Verification** - Cryptographically verify all achievements

## 🚀 Usage

### For Contract Owners

```clarity
;; Add an instructor
(contract-call? .milestone add-instructor 'SP1ABC...)

;; Remove an instructor  
(contract-call? .milestone remove-instructor 'SP1ABC...)
```

### For Instructors

```clarity
;; Create a course
(contract-call? .milestone create-course "Blockchain 101" "Introduction to blockchain technology")

;; Enroll a student
(contract-call? .milestone enroll-student 'SP1STUDENT... u1)

;; Create a milestone
(contract-call? .milestone create-milestone 
    u1                                    ;; course-id
    "Smart Contracts Basics"              ;; name
    "Complete smart contract tutorial"    ;; description  
    u1                                    ;; level (1-10)
    none                                  ;; no prerequisite
    u100)                                 ;; points

;; Award milestone completion
(contract-call? .milestone complete-milestone 
    'SP1STUDENT...                        ;; student
    u1                                    ;; milestone-id
    u85                                   ;; score (0-100)
    "https://badges.edu/blockchain101")   ;; badge URI
```

### For Students & Public

```clarity
;; Check if student completed milestone
(contract-call? .milestone has-completed-milestone 'SP1STUDENT... u1)

;; Get student progress
(contract-call? .milestone get-student-progress 'SP1STUDENT...)

;; Get milestone details
(contract-call? .milestone get-milestone u1)

;; Verify milestone completion
(contract-call? .milestone get-student-milestone 'SP1STUDENT... u1)
```

## 🏗️ Contract Structure

### Data Maps

- **instructors** - Authorized instructors
- **courses** - Course information and metadata
- **milestones** - Milestone definitions with prerequisites
- **student-enrollments** - Course enrollment records
- **student-milestones** - Completed milestone badges
- **student-progress** - Aggregated progress statistics
- **milestone-completions** - Completion counts per milestone

### Key Functions

| Function | Access | Description |
|----------|---------|-------------|
| `add-instructor` | Owner | Authorize new instructor |
| `create-course` | Instructor | Create new course |
| `enroll-student` | Instructor | Enroll student in course |
| `create-milestone` | Instructor | Define new milestone |
| `complete-milestone` | Instructor | Award milestone badge |
| `get-student-progress` | Public | View student progress |
| `has-completed-milestone` | Public | Check completion status |

## 🔧 Development

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) CLI tool
- Node.js and npm/yarn

### Setup

```bash
# Clone the repository
git clone https://github.com/your-org/learning-milestones-protocol
cd learning-milestones-protocol

# Install dependencies
npm install

# Check contract syntax
clarinet check

# Run tests
clarinet test
```

### Testing

```bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/milestone_test.ts
```

## 📊 Milestone Levels

| Level | Description | Typical Use Case |
|-------|-------------|------------------|
| 1-2 | Beginner | Basic concepts, introductory material |
| 3-4 | Intermediate | Applied knowledge, practical exercises |
| 5-6 | Advanced | Complex projects, specialized skills |
| 7-8 | Expert | Advanced applications, research |
| 9-10 | Master | Capstone projects, original work |

## 🎯 Use Cases

- **🏫 Universities** - Track degree progress and issue digital diplomas
- **💼 Corporate Training** - Certify employee skill development
- **📖 Online Courses** - Verify completion of MOOC programs  
- **🏆 Bootcamps** - Issue completion certificates and skill badges
- **🎮 Gamified Learning** - Create achievement systems for educational apps

## 🔐 Security Features

- **Access Control** - Owner-only instructor management
- **Prerequisite Validation** - Enforced milestone dependencies
- **Immutable Records** - Blockchain-based achievement verification
- **Score Validation** - Scores must be 0-100 range
- **Enrollment Verification** - Students must be enrolled to earn badges

## 📝 Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR_UNAUTHORIZED | User lacks required permissions |
| u101 | ERR_NOT_FOUND | Requested resource doesn't exist |
| u102 | ERR_ALREADY_EXISTS | Resource already exists |
| u103 | ERR_INVALID_MILESTONE | Invalid milestone parameters |
| u104 | ERR_PREREQUISITE_NOT_MET | Required prerequisite not completed |
| u105 | ERR_INVALID_LEVEL | Level must be 1-10 |
| u106 | ERR_INSTRUCTOR_REQUIRED | Function requires instructor access |
| u107 | ERR_STUDENT_NOT_ENROLLED | Student not enrolled in course |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass with `clarinet test`
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

## 🔗 Links

- [Clarinet Documentation](https://docs.hiro.so/clarinet)
- [Clarity Language Reference](https://docs.stacks.co/clarity)
- [Stacks Blockchain](https://stacks.co)
