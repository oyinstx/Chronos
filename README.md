# Chronos - Decentralized Time Banking System

[![Stacks](https://img.shields.io/badge/Stacks-blockchain-purple)](https://stacks.org/)
[![Clarity](https://img.shields.io/badge/Clarity-smart%20contracts-blue)](https://clarity-lang.org/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A decentralized time-banking system where people can exchange services and skills using time as the unit of value, creating local community economies with blockchain-verified transactions and reputation systems.

## 🌟 Overview

Chronos revolutionizes community service exchange by implementing a time-based currency system on the Stacks blockchain. Every hour of service is valued equally, regardless of the type of work, promoting true community cooperation and mutual aid.

## ✨ Features

- **Time-Based Currency**: Use time hours as the fundamental unit of exchange
- **Service Marketplace**: Create and request services within the community
- **Reputation System**: Build trust through blockchain-verified ratings and feedback
- **Transparent Transactions**: All exchanges recorded immutably on-chain
- **Community Building**: Foster local economies and social connections
- **Equal Value Principle**: Every hour of work is valued equally

## 🏗️ Architecture

### Smart Contract Functions

**User Management:**
- `register-user()` - Join the time banking community
- `get-user(principal)` - Retrieve user profile information
- `get-time-balance(principal)` - Check available time credits

**Service Management:**
- `create-service(title, description, time-required, category)` - List a service offering
- `request-service(service-id)` - Request to fulfill a service
- `complete-service(service-id)` - Mark service as completed and transfer credits
- `get-service(service-id)` - Get service details

**Reputation & Feedback:**
- `rate-service(service-id, rating, feedback)` - Rate completed services
- `get-reputation(principal)` - View user reputation score
- `get-service-rating(service-id)` - Get service ratings and feedback

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks development environment
- [Node.js](https://nodejs.org/) (v16 or later)
- [Git](https://git-scm.com/)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/chronos.git
cd chronos
```

2. Install dependencies:
```bash
clarinet requirements
```

3. Run tests:
```bash
clarinet test
```

4. Deploy locally:
```bash
clarinet console
```

## 💡 Usage Examples

### Register as a User
```clarity
(contract-call? .chronos register-user)
```

### Create a Service Offering
```clarity
(contract-call? .chronos create-service 
  "Web Development" 
  "Build a responsive website using modern frameworks" 
  u8 
  "Technology")
```

### Request a Service
```clarity
(contract-call? .chronos request-service u1)
```

### Complete and Rate a Service
```clarity
;; Complete the service (as provider)
(contract-call? .chronos complete-service u1)

;; Rate the service (as requester)
(contract-call? .chronos rate-service u1 u5 "Excellent work, highly recommended!")
```

## 🧪 Testing

Run the comprehensive test suite:

```bash
clarinet test
```

The test suite covers:
- User registration and profile management
- Service creation and lifecycle
- Time credit transfers
- Reputation system functionality
- Error handling and edge cases

## 🗺️ Roadmap

### Future Upgrade Features

1. **Multi-Currency Support** - Enable trading between time credits and STX/other tokens for broader ecosystem integration

2. **Recurring Services** - Implement subscription-based services (weekly cleaning, monthly consulting) with automated scheduling

3. **Escrow System** - Add dispute resolution mechanism with community arbitrators and locked funds during conflicts

4. **Skill Verification** - Integrate credential verification system with certificates and endorsements from trusted community members

5. **Geographic Filtering** - Add location-based service discovery and radius-limited community formation

6. **Mobile DApp Integration** - Build React Native mobile application with push notifications and offline capability

7. **Advanced Analytics Dashboard** - Comprehensive metrics for community health, service trends, and economic indicators

8. **Group Services** - Enable collaborative services where multiple providers work together on larger projects

9. **Time Savings Accounts** - Allow users to earn interest on deposited time credits and create lending mechanisms

10. **Cross-Community Exchange** - Enable inter-community trading and service sharing between different geographic regions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

*Building stronger communities, one hour at a time* ⏰