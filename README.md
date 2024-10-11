# Lawyers and Clients Database

This project consists of a structured database schema for managing lawyers, their clients, cases, documents, and billing information. It is designed to facilitate the organization and retrieval of data related to legal services.

## Database Schema

The database includes the following tables:

- **Client**: Stores information about clients, including name, address, phone number, and email.
- **Lawyer**: Contains details about lawyers, such as name, specialization, office phone number, email, office number, hourly billing rate, and partnership status.
- **Cases**: Represents legal cases, storing the case ID, title, description, status, lawyer in charge, and associated client.
- **Documents**: Holds information about documents related to each case, including case ID, document name, and document type.
- **Billing**: Records billing information, including billing date, lawyer, case ID, hours worked, work description, and total amount.
- **OnCase**: Tracks additional lawyers working on a case, their roles, and associated case IDs.

## Requirements

- SQL-compatible database management system to execute the provided SQL scripts.

## Queries

The project includes various queries written in relational algebra to extract meaningful information from the database, such as:

1. Listing lawyers who submitted hour reports for a specific case.
2. Finding lawyers who are also clients and assist in cases where they earn more per hour than the lead lawyer.
3. Identifying cases handled by a lawyer with a specific partner status.

## Usage

To use this database schema:

1. Import the SQL script into your SQL database management system.
2. Run the queries provided in the project to retrieve information based on your requirements.
