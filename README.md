# Inventory Management App

A Flutter + Firebase Firestore app that allows users to manage inventory items with full **Create, Read, Update, and Delete (CRUD)** functionality.  
All data is stored and updated in real time using Firestore.

## Enhanced Features Implemented

1. **Advanced Search & Filtering**  
   - Added a search bar that filters items by name as you type.  
   - Added filter chips for category selection and a “Low Stock” option (items with quantity < 5).  

2. **Data Insights Dashboard**  
   - Added a dashboard screen showing:  
     - Total number of unique items  
     - Total inventory value (quantity × price)  
     - A list of out-of-stock items  

## How to Run the App

1. **Clone or download** this project to your local machine.  
2. Open the project in **Android Studio** or **VS Code**.  
3. Make sure you have Flutter and Firebase CLI installed and configured.  
4. Run the following commands in the terminal:

   flutter pub get
   flutter run