# TODO & Future Plans - Homie Ecosystem

## Development Guidelines 📋
**See `GENERAL_RULES.md` for complete development guidelines including date management, commit formats, and coding standards.**

## 🎯 **Current Status: SQLite Database Foundation - Phase 1** 🚀

### **Implementation Roadmap Overview**

#### **🚀 Phase 1: SQLite Database Foundation** (CURRENT - 1-2 weeks)
**Goal**: Replace scattered `.homie_memory.json` files with centralized SQLite database for destination consistency

#### **🔮 Phase 2: Authentication & Multi-Backend** (2-4 weeks later)  
**Goal**: Support both local development and future cloud deployment with unified login

#### **🌐 Phase 3: AWS & Commercial Platform** (Future - 3+ months)
**Goal**: Cloud hosting and commercial viability with subscription model

### Recently Completed ✅ (2025-07-22)
- [x] **Multi-User Architecture Documentation**: Comprehensive documentation of local NAS vs cloud backend scenarios
- [x] **SQLite Database Schema**: Designed destination_mappings, series_mappings, user_drives, file_actions tables
- [x] **Centralized Authentication Design**: Authentication service outside individual modules for unified login
- [x] **Module-Specific Launch Scripts**: Created 4 standalone startup scripts for focused user experience
- [x] **File Organizer Scripts**: `start_file_organizer.sh` and `start_file_organizer_web.sh` launch only File Organizer
- [x] **Financial Manager Scripts**: `start_financial.sh` and `start_financial_web.sh` launch only Financial Manager  
- [x] **Command Line Route Arguments**: Flutter app accepts `--route=/module` arguments via `main(List<String> args)`
- [x] **Conditional Back Button**: Back buttons hidden in standalone launches using `isStandaloneLaunch` parameter
- [x] **Architecture Decision**: Maintained single codebase; no module exclusion from builds (Flutter tree-shaking handles optimization)
- [x] **Focused User Experience**: Standalone scripts provide single-purpose application experience without navigation distractions

### Previously Completed ✅
- [x] **Flutter Project Setup**: Complete Flutter app structure with dependencies
- [x] **Cross-Platform Support**: Android, iOS, Web, Desktop compatibility
- [x] **Dark Theme Implementation**: Material 3 dark theme with modern design
- [x] **State Management**: Provider pattern for reactive state updates
- [x] **API Integration**: Complete API service layer for backend communication
- [x] **Data Models**: JSON serialization for all data structures
- [x] **Dashboard Implementation**: Main dashboard with module cards
- [x] **File Organizer Module**: Complete implementation with stats, files, and rules
- [x] **Financial Manager Module**: Austrian tax-compliant financial tracking
- [x] **Navigation System**: Go Router for declarative routing
- [x] **Responsive Design**: Mobile-first design optimized for all screen sizes
- [x] **Documentation Updates**: Updated all docs to reflect Flutter implementation
- [x] **UI/UX Redesign**: Clean, professional design with minimal approach
- [x] **API Endpoint Fixes**: Fixed CORS errors by using actual backend endpoints
- [x] **Theme Optimization**: Removed visual clutter, improved readability and contrast

## 🚀 **Phase 1: SQLite Database Foundation** (CURRENT)

### **Week 1: Database Foundation** 
- [ ] **SQLite Database Setup**: Create `backend/data/homie.db` with all required tables
  - [ ] destination_mappings table for file category → folder mappings
  - [ ] series_mappings table for TV show → folder consistency  
  - [ ] user_drives table for available storage locations
  - [ ] file_actions table for action history
  - [ ] users table for authentication foundation
- [ ] **DatabaseService Class**: Centralized database operations with user_id isolation
- [ ] **Migration Script**: Import existing `.homie_memory.json` data into SQLite database
- [ ] **Basic Testing**: Ensure database operations work correctly

### **Week 2: Destination Memory System**
- [ ] **Drive Discovery**: Cross-platform detection of local, network, cloud, USB drives
- [ ] **Destination Tracking**: AI learns patterns like "movies → `/drive1/Movies`" from database
- [ ] **API Endpoints**: Backend endpoints for destination management and visualization
- [ ] **AI Enhancement**: Feed destination memory to AI for consistent file organization
- [ ] **Flutter UI**: Visualization of destination mappings and drive discovery

### **Immediate Benefits After Phase 1**:
- ✅ **Consistent Destinations**: Movies always go to user's preferred folder
- ✅ **Multi-Drive Support**: Works across local drives, NAS, OneDrive, Dropbox
- ✅ **AI Memory**: No more "movies in different folders" - AI remembers patterns
- ✅ **Foundation Ready**: Database ready for future multi-user and cloud deployment

## 📱 **Phase 1: File Organizer** ✅ COMPLETE

### Recently Completed ✅
- [x] **Real File Operations**: Implemented actual move and delete operations with user confirmation
- [x] **User Control System**: Accept, Specify, and Delete buttons for each file with individual control
- [x] **Completed Actions Tracking**: Files move to "Completed Actions" section with timestamps and status icons
- [x] **Memory/Log System**: .homie_memory.json files created in both source and destination folders
- [x] **Project Detection**: .git folder recognition with no deep scanning of project directories
- [x] **Content Reading**: PDF, DOC, and TXT file content analysis for better AI categorization
- [x] **AI Re-analysis**: Re-analyze files with user input when "Specify" is used
- [x] **Compact UI Design**: Right-aligned action buttons with professional, minimal design
- [x] **Smart Archive Detection**: Enhanced AI to detect and suggest deletion of redundant archive files when extracted content exists
- [x] **Document Content Analysis**: Implemented OCR and document content analysis for PDFs, DOCs, and scanned files to determine proper categorization
- [x] **Quota Error Handling**: Comprehensive 429 error handling with user-friendly messages and actionable suggestions
- [x] **Enhanced Error Management**: Rich error types (quota, auth, API, generic) with detailed frontend display
- [x] **Archive Analysis Extension**: Extended redundant archive detection to books, documents, software and all content types
- [x] **AI Integration**: Connected AI organize endpoint to frontend interface with confidence scoring
- [x] **Flutter UI Implementation**: Complete Flutter interface with Material 3 design

### Previously Completed ✅
- [x] **Technology Stack Decision**: Python 3.8+ backend + Flutter frontend
- [x] **Project Structure**: Basic backend structure with src/, config/, tests/
- [x] **AI-Powered Organization**: Google Gemini integration for smart file categorization
- [x] **File Metadata Analysis**: Extract file type, size, content hints
- [x] **Environment Configuration**: .env setup for API keys and secrets
- [x] **Folder Discovery System**: Recursive directory scanning and mapping
- [x] **Smart Organization Logic**: AI-driven file-to-folder matching with confidence scores
- [x] **API Integration**: Connect frontend to Python backend via REST API
- [x] **Folder Selection**: Browse button and quick access paths for common directories
- [x] **Modern Dark Theme**: Material 3 design with mobile-optimized styling
- [x] **Folder Browser API**: Created backend API endpoint for browsing file system folders

### Next Enhancements for File Organizer
- [ ] **File Access Tracking**: Add file open/access timestamps to memory files (TODO: Track when files are opened)
- [ ] **Batch Operations**: Implement bulk file operations with progress tracking
- [ ] **Rollback System**: Implement file operation rollback and undo functionality using memory files
- [ ] **Auto-Archive Extraction**: Implement automatic archive extraction with password support when no content exists
- [ ] **Folder Cleanup**: Delete empty folders after successful extraction and organization
- [ ] **Extraction API**: Create backend API endpoints for archive extraction with password handling
- [ ] **Document Categorization**: Create smart document categories (contracts, receipts, personal docs, etc.) based on content analysis
- [ ] **OCR Integration**: Add OCR support for scanned PDFs and image files to extract text content
- [ ] **Memory File Analytics**: Analyze usage patterns from memory files for better AI suggestions

## 🏠 **Phase 2: Home Server/NAS** (Future)

### Core NAS Features
- [ ] **Multi-Device Access**: Support Windows, Linux, iOS, Android connections
- [ ] **File Sync Engine**: Upload, download, sync capabilities across devices
- [ ] **User Management**: Multi-user access and permissions
- [ ] **Remote Access**: Secure remote connection to home server
- [ ] **Storage Management**: Disk usage monitoring and optimization
- [ ] **Backup Systems**: Automated backup and versioning

## 🎬 **Phase 3: Media Manager** (Future)

### Netflix-Style Interface
- [ ] **Media Library Scanning**: Automatic movie/TV show detection
- [ ] **IMDB Integration**: Fetch ratings, descriptions, posters, cast information
- [ ] **Watch History Tracking**: Record viewing progress and completion
- [ ] **Recommendation Engine**: "What to watch next" based on viewing patterns
- [ ] **Progress Tracking**: Resume watching, series episode management
- [ ] **Family Profiles**: Multiple user profiles with separate watch histories
- [ ] **Search and Filter**: Advanced filtering by genre, rating, year, etc.
- [ ] **Flutter Integration**: Native mobile interface for media browsing

## 📄 **Phase 4: Document Management** (Future)

### Austrian Business Focus
- [ ] **Document Categories Setup**:
  - [ ] Zeiterfassung (time tracking) management
  - [ ] Lohnzettel (pay slips) organization
  - [ ] Rechnungen (invoices) incoming/outgoing tracking
  - [ ] Verträge (contracts) storage and reminders
  - [ ] Behörden (government) document management
- [ ] **Smart Categorization**: AI-powered document classification (building on current content analysis)
- [ ] **Search Functionality**: Full-text search across all documents
- [ ] **Tax Preparation**: Austrian tax reporting automation
- [ ] **Document Workflows**: Approval processes and notifications
- [ ] **Flutter Document Viewer**: Native mobile document viewing and management

## 💰 **Phase 5: Financial Management** ✅ IMPLEMENTED

### Austrian Tax Compliance ✅
- [x] **Dual Employment Tracking**: Employee + Self-employed income management
- [x] **Financial Overview**: Summary dashboard with key metrics
- [x] **Income Management**: Track employment and self-employment income
- [x] **Expense Tracking**: Business and personal expense categorization
- [x] **Construction Budget**: House construction cost tracking and budget management
- [x] **Tax Reporting**: Austrian tax-compliant reporting structure
- [x] **Flutter UI**: Complete mobile interface for financial management

### Account Management System ✅ COMPLETED
- [x] **User Account Creation**: Create custom accounts with different types (checking, savings, investment, cash)
- [x] **Account Deletion**: Delete user-created accounts with validation
- [x] **Legacy Account Management**: Enhanced controls for system accounts (Main, Sparkonto, etc.)
- [x] **Manual Balance Setting**: Set account balances with date tracking for historical accuracy
- [x] **Inter-Account Transfers**: Transfer money between accounts with validation
- [x] **Securities Portfolio**: Track investments with real-time gain/loss calculations
- [x] **Enhanced UI**: Comprehensive account management dialog with clean, professional design

### CSV Import Enhancement ✅ COMPLETED
- [x] **Date-Based Filtering**: Only import transactions after manual balance date
- [x] **Duplicate Prevention**: Prevent double-counting when manual balances are set
- [x] **Transaction Skipping**: Automatically skip older transactions based on manual_balance_date
- [x] **Import Statistics**: Show count of processed vs skipped transactions
- [x] **Backend Integration**: Enhanced FinancialManager with date filtering logic

### Recently Completed ✅
- [x] **AccountBalance Enhancement**: Added manual_balance_date field for tracking when balances were manually set
- [x] **UserAccount Dataclass**: New dataclass for user-created accounts with comprehensive metadata
- [x] **Security Dataclass**: Investment tracking with symbol, quantity, prices, and gain/loss calculations
- [x] **Enhanced API Endpoints**: Account creation, deletion, balance setting with date tracking
- [x] **Frontend Account Management**: Comprehensive AccountManagementDialog with all features
- [x] **CSV Import Date Logic**: Core filtering logic to process only newer transactions
- [x] **UI/UX Improvements**: Removed clutter, added "Manage Accounts" button, redesigned interface

### Future Financial Enhancements
- [ ] **Invoice Management**:
  - [ ] Incoming invoice tracking for business expenses
  - [ ] Outgoing invoice management for self-employment income
  - [ ] VAT/USt calculation and tracking
  - [ ] Automated tax reporting
- [ ] **Enhanced Construction Tracking**:
  - [ ] Real-time cost tracking against budget
  - [ ] Supplier invoice management and payment scheduling
  - [ ] Cost category analysis (materials, labor, permits)
  - [ ] Budget variance reporting
- [ ] **Credit/Loan Management**:
  - [ ] Monthly payment tracking and reminders
  - [ ] Interest calculation and projections
  - [ ] Early payment scenario planning
- [ ] **Financial Forecasting**:
  - [ ] Cash flow predictions based on income/expenses
  - [ ] House construction affordability timeline
  - [ ] Major purchase planning and savings goals
  - [ ] Emergency fund tracking and recommendations
- [ ] **Advanced Account Features**:
  - [ ] Account categories and tagging
  - [ ] Recurring transaction templates
  - [ ] Budget allocation per account
  - [ ] Transaction history export
  - [ ] Account performance analytics

## 🌍 **Phase 6: DACH Market Expansion** (Future Commercial Opportunity)

### **Market Research Findings ✅ COMPLETED (2025-01-XX)**
Based on comprehensive research of Austrian, German, and Swiss invoice requirements and VAT regulations, **expansion to Germany and Switzerland is highly viable and strategically valuable**.

### **Key Market Insights:**
- **Unified DACH Strategy**: All three countries share EU VAT framework basics and similar business compliance requirements
- **Germany Market Size**: 9x larger than Austria (3.5M vs 400K businesses) = massive revenue potential
- **Switzerland Premium Market**: Highest business income in Europe, willingness to pay premium for compliance tools
- **Technical Compatibility**: 80% of current Austrian solution can be reused for Germany/Switzerland
- **Perfect Timing**: Germany introducing mandatory B2B e-invoicing 2025-2028 creates urgent market need

### **Revenue Potential Analysis:**
- **Austria**: €10-20M total addressable market
- **Germany**: €70-140M total addressable market  
- **Switzerland**: €15-30M total addressable market
- **Combined DACH**: €95-190M total market opportunity

### **Recommended Implementation Priority:**
1. **Germany First** (Next 6 months): Urgent need due to 2025 e-invoicing mandate
2. **Switzerland Next** (6-12 months): Premium market with high-value customers

### **AI Invoice Processor DACH Expansion Features:**
- [ ] **German Market Entry**:
  - [ ] German CEN 16931 format support for mandatory e-invoicing
  - [ ] DATEV export format integration (German accounting standard)
  - [ ] German tax rate validation (19% standard, 7% reduced)
  - [ ] German business number patterns and validation
  - [ ] Partnership with German tax advisors and accounting firms
- [ ] **Swiss Market Entry**:
  - [ ] CHE business number validation system
  - [ ] Swiss accounting software integrations (Abacus, etc.)
  - [ ] Multi-currency support with CHF focus
  - [ ] Swiss VAT rate handling (7.7% standard)
  - [ ] Premium positioning for high-value Swiss businesses
- [ ] **Unified DACH Platform**:
  - [ ] Single AI core handling all three countries
  - [ ] Country-specific validation modules
  - [ ] Multi-language support (German with Austrian/Swiss variants)
  - [ ] Unified pricing and billing system
  - [ ] DACH-wide customer support

### **Business Model Expansion:**
- [ ] **Pricing Strategy by Market**:
  - [ ] Germany: €19-39/month (competitive, volume-based)
  - [ ] Austria: €29-49/month (specialized compliance premium)
  - [ ] Switzerland: €39-79/month (premium market positioning)
- [ ] **Revenue Projections**:
  - [ ] Year 1: €442K (focus on Germany + existing Austria)
  - [ ] Year 2: €1.42M (add Switzerland, scale Germany)
  - [ ] Year 3-4: €5M+ potential with market penetration
- [ ] **Marketing Channels**:
  - [ ] German tax advisor partnerships for e-invoicing mandate
  - [ ] Austrian business association relationships
  - [ ] Swiss multinational corporate direct sales

### **Technical Implementation Requirements:**
- [ ] **Core AI Engine Enhancement** (20% new development):
  - [ ] Country-specific VAT number format validation
  - [ ] Local accounting software export formats
  - [ ] Multi-country invoice template recognition
  - [ ] Currency and tax rate handling per country
- [ ] **Regulatory Compliance**:
  - [ ] German CEN 16931 European standard compliance
  - [ ] Austrian e-Rechnung.gv.at format compatibility
  - [ ] Swiss CHE business registry integration
  - [ ] GDPR compliance across all DACH countries

### **Success Metrics:**
- [ ] **Year 1 Targets**:
  - [ ] Germany: 1,000+ customers (€348K ARR)
  - [ ] Austria: 200+ customers (€94K ARR)
- [ ] **Year 2 Targets**:
  - [ ] Germany: 3,000+ customers (€1.04M ARR)
  - [ ] Switzerland: 200+ customers (€142K ARR)
  - [ ] Total DACH: €1.4M+ annual recurring revenue

**Note**: This DACH expansion represents a **€5M+ business opportunity** within 3-4 years, leveraging existing Austrian expertise across the German-speaking business compliance market.

## 🔧 **Technical Infrastructure** (Ongoing)

### Core System Improvements
- [x] **Flutter Architecture**: Complete cross-platform app architecture
- [x] **API Framework**: RESTful API design for all module interactions
- [x] **State Management**: Provider pattern for reactive state updates
- [x] **Mobile-First Design**: Responsive design optimized for mobile devices
- [ ] **Database Architecture**: Design unified schema for all modules
- [ ] **Authentication System**: User management and security
- [ ] **Offline Capabilities**: Core functions working without internet
- [ ] **Data Backup**: Comprehensive backup and restore system
- [ ] **Performance Optimization**: Handle large datasets efficiently

### Security & Privacy
- [ ] **Data Encryption**: Encrypt sensitive financial and personal data
- [ ] **Access Control**: Role-based permissions for family members
- [ ] **Audit Logging**: Track all financial and document changes
- [ ] **GDPR Compliance**: European privacy regulation compliance

## 📱 **Mobile-First Design Principles** ✅ IMPLEMENTED

### Design Guidelines ✅
- [x] **Touch-First**: All interactions optimized for touchscreen
- [x] **Thumb-Friendly**: Important actions within thumb reach
- [x] **Responsive Layout**: Perfect on all screen sizes
- [x] **Material 3 Design**: Modern dark theme with consistent styling
- [x] **Cross-Platform**: Single codebase for mobile, web, and desktop
- [ ] **Gesture Support**: Swipe, pinch, and touch gestures
- [ ] **Fast Loading**: Optimized for mobile network speeds
- [ ] **Offline Support**: Critical functions work without internet

## 🎯 **Success Metrics**

### User Experience Goals
- [x] **Cross-Platform Compatibility**: Single app works on all platforms
- [x] **Modern UI**: Material 3 dark theme with intuitive navigation
- [x] **Module Integration**: Seamless navigation between modules
- [ ] **One-Touch Access**: Most common tasks achievable in 1-2 taps
- [ ] **Mobile Performance**: < 3 second load times on mobile
- [ ] **Adoption Rate**: Daily usage of at least 3 modules
- [ ] **Error Reduction**: 90% reduction in financial/document errors
- [ ] **Time Savings**: 50% reduction in administrative task time

## 🚫 **Removed/Cancelled Items**
- ~~Svelte Frontend~~ - Replaced with Flutter for cross-platform support
- ~~Web-Only Interface~~ - Replaced with mobile-first Flutter app
- ~~API Usage Monitoring~~ - Google's Gemini API provides no real quota checking functionality
- ~~Usage Display Frontend~~ - Not feasible without real quota data from Google
