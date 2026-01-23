# Database Schema Fix for Orders Status

## Issue
The code is trying to access `orders.status` column which doesn't exist in the database schema.

## Current Schema
Your orders table has:
- `buyer_status` (buyer_order_status enum)
- `farmer_status` (farmer_order_status enum)

## Code Changes Made
1. **farmer_dashboard_screen.dart**: Changed `orders.status` to `orders.farmer_status`
2. **store_management_service.dart**: Fixed storage bucket references

## Additional Files That May Need Updates
If you encounter similar errors, search for:
- `.eq('status', ` in orders-related queries
- Replace with either `.eq('buyer_status', ` or `.eq('farmer_status', ` as appropriate

## Status Values
Based on your schema:
- **farmer_status**: 'newOrder', 'accepted', 'preparing', 'ready', 'completed'
- **buyer_status**: 'pending', 'confirmed', 'shipped', 'delivered'