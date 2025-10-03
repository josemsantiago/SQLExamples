# SQL Learning Examples
### SQL and Transact-SQL Practice Repository

[![SQL](https://img.shields.io/badge/SQL-Learning-blue.svg)](https://www.w3schools.com/sql/)
[![T-SQL](https://img.shields.io/badge/T--SQL-In_Progress-orange.svg)](https://docs.microsoft.com/en-us/sql/t-sql/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A growing collection of SQL examples for learning and practice, focusing on the Museum of Modern Art (MoMA) dataset and fundamental SQL concepts.

## 📚 **Table of Contents**

- [Overview](#overview)
- [Database Schema](#database-schema)
- [SQL Fundamentals](#sql-fundamentals)
- [Advanced Queries](#advanced-queries)
- [Transact-SQL Features](#transact-sql-features)
- [Performance Optimization](#performance-optimization)
- [Data Analysis Examples](#data-analysis-examples)
- [Enterprise Patterns](#enterprise-patterns)
- [Setup Instructions](#setup-instructions)

## 🎯 **Overview**

This repository contains SQL learning exercises and examples, primarily working with the Museum of Modern Art (MoMA) dataset. It includes basic queries, data visualization scripts, and foundational SQL concepts.

### **Current Implementation Status**

| Category | Status | Files |
|----------|--------|-------|
| **Basic Queries** | ✅ Implemented | `queries.sql`, `01_fundamentals/basic_queries.sql` |
| **Data Mutations** | ✅ Implemented | `mutations.sql` |
| **MoMA Visualization** | ✅ Implemented | `moma_viz.sql`, `moma_viz.py`, `moma_viz.ipynb` |
| **Schema Creation** | ✅ Implemented | `ShemaCreation.sql` |
| **Advanced Features** | 🚧 Planned | See roadmap below |

## 📊 **Database Schema**

### **Museum of Modern Art (MoMA) Dataset**
The primary dataset used in this project:
- **Artworks**: Art collection data including titles, dates, mediums
- **Artists**: Artist information and biographical data
- Schema creation script: `ShemaCreation.sql`

## 🔧 **Current File Structure**

```
SQLExamples/
├── queries.sql                    # Main MoMA dataset queries
├── mutations.sql                  # Data modification examples
├── momaviz.sql                    # Large MoMA visualization dataset
├── moma_viz.py                    # Python visualization script
├── moma_viz.ipynb                 # Jupyter notebook for visualizations
├── ShemaCreation.sql              # Database schema setup
├── 01_fundamentals/
│   └── basic_queries.sql          # Fundamental SQL queries
├── 02_intermediate/               # (empty - planned)
├── 03_advanced/                   # (empty - planned)
├── 04_tsql_programming/           # (empty - planned)
├── 05_performance/                # (empty - planned)
├── 06_enterprise/                 # (empty - planned)
├── 07_data_analysis/              # (empty - planned)
├── 08_real_world_scenarios/       # (empty - planned)
└── schemas/                       # (empty - planned)
```

## 🚀 **What's Implemented**

### **MoMA Dataset Analysis**
- Basic SELECT queries for artwork exploration
- Data mutation examples (INSERT, UPDATE, DELETE)
- Python-based data visualization
- Jupyter notebook for interactive analysis

### **Fundamentals**
- Basic query patterns in `01_fundamentals/basic_queries.sql`
- Schema creation and setup

## 📋 **Planned Future Content**

The following directories are placeholders for future learning:

### **Intermediate SQL** (02_intermediate/)
- JOIN operations
- Subqueries and CTEs
- Aggregate functions
- Date/time manipulation

### **Advanced SQL** (03_advanced/)
- Window functions
- Recursive queries
- PIVOT/UNPIVOT operations

### **T-SQL Programming** (04_tsql_programming/)
- Stored procedures
- Functions
- Triggers
- Error handling

### **Performance** (05_performance/)
- Indexing strategies
- Query optimization
- Execution plan analysis

### **Enterprise Features** (06_enterprise/)
- Security implementations
- Backup/recovery
- High availability patterns

### **Data Analysis** (07_data_analysis/)
- Business intelligence queries
- Statistical analysis
- Reporting patterns

### **Real-World Scenarios** (08_real_world_scenarios/)
- E-commerce queries
- Financial analysis
- Application-specific patterns

## 🛠 **Setup Instructions**

### **Prerequisites**
- SQL Server or PostgreSQL
- SQL Server Management Studio, Azure Data Studio, or similar SQL client
- Python 3.x (for visualization scripts)

### **Database Setup**
```bash
# 1. Create the MoMA database schema
sqlcmd -S your_server -i ShemaCreation.sql

# 2. Load the MoMA dataset
sqlcmd -S your_server -i momaviz.sql

# 3. Try out the example queries
sqlcmd -S your_server -i queries.sql
```

### **Python Visualization**
```bash
# Install dependencies
pip install matplotlib pandas sqlalchemy

# Run visualization script
python moma_viz.py

# Or use Jupyter notebook
jupyter notebook moma_viz.ipynb
```

## 📚 **Learning Progress**

### **Completed**
- ✅ Basic SELECT queries
- ✅ Data mutations (INSERT, UPDATE, DELETE)
- ✅ Schema design fundamentals
- ✅ Data visualization with Python

### **In Progress**
- 🚧 Intermediate query techniques
- 🚧 JOIN operations
- 🚧 Aggregate functions

### **Planned**
- 📋 Window functions
- 📋 Stored procedures
- 📋 Performance optimization
- 📋 Advanced T-SQL features

## 📸 Screenshots

> **Note:** Query result screenshots and ER diagrams will be added soon. Run the SQL scripts to see the queries in action.

## 🐛 Troubleshooting

### Common Issues

**Issue:** Cannot connect to SQL Server

**Solution:** Ensure SQL Server is running and you have the correct connection string. For local instances:
```bash
sqlcmd -S localhost -E
# Or specify username/password
sqlcmd -S localhost -U sa -P YourPassword
```

---

**Issue:** Python visualization script fails

**Solution:** Install required dependencies:
```bash
pip install matplotlib pandas sqlalchemy pyodbc
```

---

**Issue:** Large SQL file (momaviz.sql) takes too long to load

**Solution:** This is a 332KB file with extensive data. Be patient or import in smaller batches. Consider using bulk import for production scenarios.

---

**Issue:** Missing SQL client tools

**Solution:** Install one of these:
- **SQL Server Management Studio (SSMS)**: [Download](https://docs.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms)
- **Azure Data Studio**: [Download](https://docs.microsoft.com/en-us/sql/azure-data-studio/download-azure-data-studio)
- **DBeaver**: [Download](https://dbeaver.io/download/)

---

**Issue:** Schema creation fails

**Solution:** Ensure you have CREATE DATABASE permissions and that no database with the same name exists.

For additional help, please open an issue in the repository issue tracker.

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/YourFeature`)
3. Commit your changes (`git commit -m 'Add YourFeature'`)
4. Push to the branch (`git push origin feature/YourFeature`)
5. Open a Pull Request

### Enhancement Ideas
- Complete the planned directories (02-08)
- Add more real-world dataset examples
- Create video tutorials for complex queries
- Add PostgreSQL equivalent examples
- Include MySQL syntax variations
- Add comprehensive comments to existing queries

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📧 Contact & Support

- **Author**: José Santiago Echevarria
- **Issues**: Please report bugs via the repository issue tracker
- **Educational Purpose**: SQL learning through practical examples with real datasets
- **Dataset**: Museum of Modern Art (MoMA) collection data

---

*A growing SQL learning project focused on practical examples and data analysis.*