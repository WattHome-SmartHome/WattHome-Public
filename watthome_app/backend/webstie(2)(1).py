from flask import Flask, Response, request, jsonify, g, send_file
from datetime import datetime, timedelta
import mysql.connector
from flask_cors import CORS 
import urllib.parse

app = Flask(__name__)
CORS(app)


# Function to generate HTTPS URI from SQL query and return it
def get_https_uri_for_sql_query(sql_query):
    # URL-encode the SQL query to ensure it's properly formatted for a URL
    encoded_query = urllib.parse.quote(sql_query)
    
    # Construct the full HTTPS URI for the /connection route
    base_url = "http://127.0.0.1:5000/connection"  # Replace with your domain or localhost
    https_uri = f"{base_url}?statm={encoded_query}"
    
    # Return the generated URI
    return https_uri

# Database connection function
def get_db_connection():
    if 'db' not in g:
        g.db = mysql.connector.connect(
            host='localhost',        
            user='root',             
            password='password',  
            database='watthome', 
            port=3306,    
            charset='utf8mb4',
            collation='utf8mb4_unicode_ci'
        )
    return g.db

# Close DB connection
@app.teardown_appcontext
def close_db_connection(exception=None):
    db = g.pop('db', None)
    if db is not None:
        db.close()

# Home route
@app.route('/')
def home():
    # Example SQL query to test URI generation
    sql_query = "SELECT * FROM ChallengeParticipants;"
    
    # Generate the URI
    uri = get_https_uri_for_sql_query(sql_query)
    
    return f"HELLO NAHVENOSVN {uri}"




import mysql.connector
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import random
import pandas as pd
import numpy as np
import seaborn as sns
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, firestore
import matplotlib.dates as mdates
from matplotlib.backends.backend_pdf import PdfPages
import matplotlib.gridspec as gridspec
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from reportlab.lib import colors  # This was missing
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER
from reportlab.lib import colors
import io
import os
from pathlib import Path

# Initialize Firebase Admin SDK
cred = credentials.Certificate(r"") # Add your own Firebase Admin SDK JSON file
firebase_admin.initialize_app(cred)


# Initialize Firestore
db = firestore.client()

def get_admin_name():
    users_ref = db.collection("users").where("role", "==", "Admin").limit(1).get()
    for user in users_ref:
        return user.to_dict().get("name", "Admin User")
    return "Admin User"

def generate_energy_report(home_id, start_date, end_date, output_pdf_path):
    # Connect to MySQL
    try:


        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)


        if connection.is_connected():
            print("Connected to MySQL Server successfully!")
            cursor = connection.cursor()
            
            # Create a PDF document
            doc = SimpleDocTemplate(output_pdf_path, pagesize=letter)
            styles = getSampleStyleSheet()
            story = []
            
            # Create custom styles
            title_style = ParagraphStyle(
                'Title',
                parent=styles['Heading1'],
                fontSize=22,
                alignment=TA_CENTER,
                spaceAfter=16
            )
            
            subtitle_style = ParagraphStyle(
                'Subtitle',
                parent=styles['Heading2'],
                fontSize=16,
                alignment=TA_CENTER,
                spaceAfter=10
            )
            
            normal_style = styles['Normal']
            
            # Get admin name
            admin_name = get_admin_name()
            
            # Create temporary directory for saving chart images
            temp_dir = "temp_charts"
            os.makedirs(temp_dir, exist_ok=True)
            
            # ====== PAGE 1: TITLE, ADMIN NAME, AND TOTAL CONSUMPTION CHART ======
            
            # Total consumption and generation stats
            cursor.execute("""
                SELECT SUM(energy_consumed) AS total_energy_consumed,
                       SUM(energy_generated) AS total_energy_generated
                FROM energy_data
                WHERE home_id = %s AND DATE(timestamp) BETWEEN %s AND %s
            """, (home_id, start_date, end_date))
            
            total_energy = cursor.fetchone()
            total_consumed = total_energy[0] if total_energy[0] else 0
            total_generated = total_energy[1] if total_energy[1] else 0
            
            # Add title and admin name
            story.append(Paragraph(f"Energy Consumption Report", title_style))
            story.append(Spacer(1, 0.2*inch))
            
            # Add summary table
            summary_data = [
                ["User", admin_name],
                ["Home ID", home_id],
                ["Start Date", start_date],
                ["End Date", end_date],
                ["Total Energy Consumed", f"{total_consumed:.2f} kWh"],
                ["Total Energy Generated", f"{total_generated:.2f} kWh"]

            ]
            
            summary_table = Table(summary_data, colWidths=[3*inch, 2*inch])
            summary_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (0, -1), '#ADD8E6'),
                ('TEXTCOLOR', (0, 0), (0, -1), '#000000'),
                ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ('FONTNAME', (0, 0), (-1, -1), 'Helvetica-Bold'),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
                ('BACKGROUND', (1, 0), (1, -1), "#FFFFFF"),
                ('GRID', (0, 0), (-1, -1), 1, "#000000")
            ]))
            
            story.append(summary_table)
            story.append(Spacer(1, 0.3*inch))
            
            # Total consumption Chart
            cursor.execute("""
                SELECT home_id, DATE(timestamp) AS date, HOUR(timestamp) AS hour,  
                      SUM(energy_consumed) AS total_energy_consumed
                FROM energy_data
                WHERE home_id = %s AND DATE(timestamp) BETWEEN %s AND %s
                GROUP BY home_id, date, hour
                ORDER BY home_id, date, hour
            """, (home_id, start_date, end_date))

            total_energy_data = cursor.fetchall()
            
            # Process data for total energy consumption
            timestamps = []
            energy_consumed = []

            for row in total_energy_data:
                timestamp = datetime.strptime(f"{row[1]} {row[2]}:00:00", '%Y-%m-%d %H:%M:%S')
                timestamps.append(timestamp)
                energy_consumed.append(row[3])
            
            # Create a variable for the total consumption chart path
            total_consumption_chart = f"{temp_dir}/total_consumption.png"
            
            # Generate total consumption chart
            if timestamps and energy_consumed:
                plt.figure(figsize=(8, 5))
                plt.plot(timestamps, energy_consumed, label="Total Energy Consumption", marker='o', color='r')
                plt.ylabel('Energy Consumed (kWh)')
                plt.title(f'Total Energy Consumption from {start_date} to {end_date}')
                plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%b %d %H:%M'))
                plt.xticks(rotation=45)
                plt.grid()
                plt.tight_layout()
                
                # Save chart to temporary file
                plt.savefig(total_consumption_chart, dpi=300, bbox_inches='tight')
                plt.close()
                
                # Add chart to the story
                story.append(Paragraph("Total Energy Consumption", subtitle_style))
                story.append(Image(total_consumption_chart, width=6*inch, height=4*inch))
            
            # Add page break
            story.append(Spacer(1, 0.7*inch))
            story.append(Paragraph("", normal_style))
            story.append(Paragraph("", normal_style))
            
            # ====== PAGE 2: APPLIANCE CHARTS ======
            
            story.append(Paragraph("Appliance Energy Consumption Analysis", title_style))
            story.append(Spacer(1, 0.2*inch))
            
            # Appliance-specific line charts
            cursor.execute("""
                SELECT home_id, appliance_name, DATE(timestamp) AS date, HOUR(timestamp) AS hour,  
                       SUM(energy_consumed) AS total_energy_consumed
                FROM appliancecontrolenergy_data
                WHERE home_id = %s AND DATE(timestamp) BETWEEN %s AND %s
                GROUP BY home_id, appliance_name, date, hour
                ORDER BY home_id, date, hour
            """, (home_id, start_date, end_date))

            summarized_energy_data = cursor.fetchall()
            
            # Process the data for appliance-specific charts
            appliances_data = {}
            
            for row in summarized_energy_data:
                appliance_name = row[1]
                timestamp = datetime.strptime(f"{row[2]} {row[3]}:00:00", '%Y-%m-%d %H:%M:%S')
                total_energy_consumed = row[4]

                if appliance_name not in appliances_data:
                    appliances_data[appliance_name] = {'timestamps': [], 'energy_consumed': []}
                
                appliances_data[appliance_name]['timestamps'].append(timestamp)
                appliances_data[appliance_name]['energy_consumed'].append(total_energy_consumed)
            
            # Create and save individual appliance charts
            appliance_charts = []
            for i, (appliance_name, data) in enumerate(appliances_data.items()):
                plt.figure(figsize=(5, 3))
                colors = ['#0000FF', '#008000','#00FFFF', '#FF00FF', '#FFFF00']
                plt.plot(data['timestamps'], data['energy_consumed'], label=appliance_name, color=colors[i], marker='o')
                plt.xlabel('Timestamp')
                plt.ylabel('Energy (kWh)')
                plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%b %d %H'))
                plt.xticks(rotation=45, fontsize=8)
                plt.grid()
                plt.tight_layout()
                
                # Save chart
                chart_path = f"{temp_dir}/appliance_{i}.png"
                plt.savefig(chart_path, dpi=200, bbox_inches='tight')
                plt.close()
                appliance_charts.append((chart_path, appliance_name))
            
            # Appliance pie chart
            cursor.execute("""
                SELECT appliance_name, SUM(energy_consumed) AS total_energy_consumed
                FROM appliancecontrolenergy_data
                WHERE home_id = %s AND DATE(timestamp) BETWEEN %s AND %s
                GROUP BY appliance_name
                ORDER BY total_energy_consumed DESC
            """, (home_id, start_date, end_date))

            appliance_energy_data = cursor.fetchall()
        
            appliance_names = [row[0] for row in appliance_energy_data]
            energy_values = [row[1] for row in appliance_energy_data]

            if appliance_names and energy_values:
                # Plot the pie chart
                plt.figure(figsize=(6, 6))
                plt.pie(energy_values, labels=appliance_names, autopct='%1.1f%%', startangle=140, 
                        colors=plt.cm.Paired.colors, wedgeprops={'edgecolor': 'black'})
                plt.axis('equal')
                
                # Save chart
                pie_chart_path = f"{temp_dir}/appliance_pie.png"
                plt.savefig(pie_chart_path, dpi=200, bbox_inches='tight')
                plt.legend(title='Appliance')
                plt.close()
                appliance_charts.append((pie_chart_path, "Appliance Distribution"))
            
            # Appliance area chart
            cursor.execute("""
                SELECT home_id, appliance_name, DATE(timestamp) AS date, HOUR(timestamp) AS hour,  
                    SUM(energy_consumed) AS total_energy_consumed
                FROM appliancecontrolenergy_data
                WHERE home_id = %s AND DATE(timestamp) BETWEEN %s AND %s
                GROUP BY home_id, appliance_name, date, hour
                ORDER BY home_id, date, hour
            """, (home_id, start_date, end_date))

            summarized_energy_data = cursor.fetchall()

            # Process the data into a DataFrame for area chart
            data = []
            for row in summarized_energy_data:
                appliance_name = row[1]
                time_label = f"{row[2]} {row[3]}:00"
                total_energy_consumed = row[4]
                data.append([time_label, appliance_name, total_energy_consumed])

            if data:
                df = pd.DataFrame(data, columns=['Time', 'Appliance', 'Energy_Consumed'])
                df_pivot = df.pivot(index='Time', columns='Appliance', values='Energy_Consumed').fillna(0)
                df_pivot = df_pivot.sort_index()

                # Plot the stacked area chart
                plt.figure(figsize=(6, 4))
                df_pivot.plot(kind='area', stacked=True, colormap='tab10', alpha=0.7)
                plt.xlabel('Timestamp')
                plt.ylabel('Energy (kWh)')
                plt.xticks(rotation=45, ha='right', fontsize=8)
                plt.legend(title='Appliance', bbox_to_anchor=(1.05, 1), loc='upper left', fontsize=8)
                plt.grid(axis='y', linestyle='--', alpha=0.7)
                plt.tight_layout()
                
                # Save chart
                area_chart_path = f"{temp_dir}/appliance_area.png"
                plt.savefig(area_chart_path, dpi=200, bbox_inches='tight')
                plt.close()
                appliance_charts.append((area_chart_path, "Appliance Energy Over Time"))
            
            # Add appliance charts to the story - organize in pairs
            for i in range(0, len(appliance_charts), 2):
                data = []
                row = []
                titles = []
                
                for j in range(2):
                    if i + j < len(appliance_charts):
                        chart_path, chart_title = appliance_charts[i + j]
                        row.append(Image(chart_path, width=3.3*inch, height=2*inch))
                        titles.append(chart_title)
                
                data.append(row)
                
                # Create table with images
                image_table = Table(data, colWidths=[3.9*inch, 3.9*inch])
                image_table.setStyle(TableStyle([
                    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                    ('TOPPADDING', (0, 0), (-1, -1), 5),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
                ]))
                
                # Add title and table to story
                title_table = Table([[Paragraph(titles[0], normal_style)] + 
                                     ([Paragraph(titles[1], normal_style)] if len(titles) > 1 else [])], 
                                    colWidths=[3*inch, 3*inch])
                title_table.setStyle(TableStyle([
                    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ]))
                
                story.append(title_table)
                story.append(image_table)
                story.append(Spacer(1, 0.05*inch))
            
            # Add page break
            story.append(Spacer(1, 0.7*inch))
            story.append(Paragraph("", normal_style))
            story.append(Paragraph("", normal_style))
            
            # ====== PAGE 3: ROOM CHARTS ======
            
            story.append(Paragraph("Room-wise Energy Consumption Analysis", title_style))
            story.append(Spacer(1, 0.2*inch))
            
            # Room-wise energy bar chart
            cursor.execute("""
                SELECT room_name, SUM(energy_consumed) AS total_energy_consumed
                FROM appliancecontrolenergy_data
                WHERE home_id = %s AND DATE(timestamp) BETWEEN %s AND %s
                GROUP BY room_name
                ORDER BY total_energy_consumed DESC
            """, (home_id, start_date, end_date))

            room_energy_data = cursor.fetchall()
            
            room_charts = []
            
            if room_energy_data:
                room_names = [row[0] for row in room_energy_data]
                energy_values = [row[1] for row in room_energy_data]

                plt.figure(figsize=(6, 4))
                plt.barh(room_names, energy_values, color='lightblue', edgecolor='black', height=0.4)
                plt.xlabel('Total Energy Consumed (kWh)')
                plt.ylabel('Room Name')
                plt.tight_layout()
                
                # Save chart
                room_bar_chart_path = f"{temp_dir}/room_bar.png"
                plt.savefig(room_bar_chart_path, dpi=200, bbox_inches='tight')
                plt.close()
                room_charts.append((room_bar_chart_path, "Room Energy Consumption"))
            
            # Room-wise area chart
            cursor.execute("""
                SELECT home_id, room_name, DATE(timestamp) AS date, HOUR(timestamp) AS hour,  
                    SUM(energy_consumed) AS total_energy_consumed
                FROM appliancecontrolenergy_data
                WHERE home_id = %s AND DATE(timestamp) BETWEEN %s AND %s
                GROUP BY home_id, room_name, date, hour
                ORDER BY home_id, date, hour
            """, (home_id, start_date, end_date))

            summarized_energy_data = cursor.fetchall()

            # Process the data into a DataFrame for area chart
            data = []
            for row in summarized_energy_data:
                room_name = row[1]
                time_label = f"{row[2]} {row[3]}:00"
                total_energy_consumed = row[4]
                data.append([time_label, room_name, total_energy_consumed])

            if data:
                df = pd.DataFrame(data, columns=['Time', 'Room', 'Energy_Consumed'])
                df_pivot = df.pivot(index='Time', columns='Room', values='Energy_Consumed').fillna(0)
                df_pivot = df_pivot.sort_index()

                # Plot the stacked area chart
                plt.figure(figsize=(6, 4))
                df_pivot.plot(kind='area', stacked=True, colormap='Accent', alpha=0.7)
                plt.xlabel('Timestamp')
                plt.ylabel('Energy (kWh)')
                plt.xticks(rotation=45, ha='right', fontsize=8)
                plt.legend(title='Room', bbox_to_anchor=(1.05, 1), loc='upper left', fontsize=8)
                plt.grid(axis='y', linestyle='--', alpha=0.7)
                plt.tight_layout()
                
                # Save chart
                room_area_chart_path = f"{temp_dir}/room_area.png"
                plt.savefig(room_area_chart_path, dpi=200, bbox_inches='tight')
                plt.close()
                room_charts.append((room_area_chart_path, "Room Energy Distribution Over Time"))
            cursor.execute("""
                SELECT room_name, SUM(energy_consumed) AS total_energy_consumed
                FROM appliancecontrolenergy_data
                WHERE home_id = %s AND DATE(timestamp) BETWEEN %s AND %s
                GROUP BY room_name
                ORDER BY total_energy_consumed DESC
            """, (home_id, start_date, end_date))

            room_energy_data = cursor.fetchall()
        
            room_names = [row[0] for row in room_energy_data]
            energy_values = [row[1] for row in room_energy_data]


            print("I AMERES ERHESRUOES")
            print(energy_values)
            print(room_names)
            print(type(room_names))
            print(type(room_names[0]))
            if room_names and energy_values:
                # Plot the pie chart
                plt.figure(figsize=(6, 6))
                colors=["#FFFF00","#FFAE42","#FFA500","#FF4500"]
                plt.pie(energy_values, labels=room_names, autopct='%1.1f%%', startangle=140, 
                        colors=colors, wedgeprops={'edgecolor': 'black'})
                plt.axis('equal')
                
                # Save chart
                pie_chart_path = f"{temp_dir}/room_pie.png"
                plt.savefig(pie_chart_path, dpi=200, bbox_inches='tight')
                plt.legend(title='Room')
                plt.close()
                room_charts.append((pie_chart_path, "Room Distribution"))

            #Room with the highest energy consumption-Line chart
            cursor.execute("""
            SELECT room_name, SUM(energy_consumed) AS total_energy_consumed
            FROM appliancecontrolenergy_data
            WHERE home_id = %s
            AND DATE(timestamp) BETWEEN %s AND %s
            GROUP BY room_name
            ORDER BY total_energy_consumed DESC
            LIMIT 1
        """, (home_id, start_date, end_date))

            r_energy_data = cursor.fetchone()  # Use fetchone() instead of fetchall()
            if r_energy_data:
                room_name, total_energy_consumed = r_energy_data  # Unpack values

            # Fetch time-series energy data for the highest-consuming room
            cursor.execute("""
                SELECT timestamp, energy_consumed
                FROM appliancecontrolenergy_data
                WHERE home_id = %s AND room_name = %s
                AND DATE(timestamp) BETWEEN %s AND %s
                ORDER BY timestamp
            """, (home_id, room_name, start_date, end_date))

            time_series_data = cursor.fetchall()

            # Extract timestamps and energy values
            timestamps = [row[0] for row in time_series_data]
            energy_values = [row[1] for row in time_series_data]

            # Plot the data
            plt.figure(figsize=(5, 3))
            plt.plot(timestamps, energy_values, label=room_name, color='red', marker='o')
            
            plt.xlabel('Timestamp')
            plt.ylabel('Energy (kWh)')
            plt.title(f"Energy Consumption in {room_name}")
            plt.legend()
            plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%b %d %H'))
            plt.xticks(rotation=45, fontsize=8)
            plt.grid()
            plt.tight_layout()
                # Save chart
            chart_path = f"{temp_dir}/room_linechart{i}.png"
            plt.savefig(chart_path, dpi=200, bbox_inches='tight')
            plt.close()
            room_charts.append((chart_path,"Room with the highest energy consumption"))

            
            # Add room charts to the story
            for i in range(0, len(room_charts), 2):
                data = []
                row = []
                titles = []
                
                for j in range(2):
                    if i + j < len(room_charts):
                        chart_path, chart_title = room_charts[i + j]
                        row.append(Image(chart_path, width=3.4*inch, height=2.7*inch))
                        titles.append(chart_title)
                
                data.append(row)
                
                # Create table with images
                image_table = Table(data, colWidths=[4*inch, 4*inch])
                image_table.setStyle(TableStyle([
                    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
                    ('TOPPADDING', (0, 0), (-1, -1), 5),
                    ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
                ]))
                
                # Add title and table to story
                title_table = Table([[Paragraph(titles[0], normal_style)] + 
                                     ([Paragraph(titles[1], normal_style)] if len(titles) > 1 else [])], 
                                    colWidths=[4*inch, 4*inch])
                title_table.setStyle(TableStyle([
                    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                ]))
                
                story.append(title_table)
                story.append(image_table)
                story.append(Spacer(1, 0.5*inch))
            
            # Build the PDF
            doc.build(story)
            print(f"PDF report created successfully at: {output_pdf_path}")
            
            # Clean up temporary files
            for chart_path, _ in appliance_charts + room_charts:
                if os.path.exists(chart_path):
                    os.remove(chart_path)
            if os.path.exists(total_consumption_chart):
                os.remove(total_consumption_chart)
            if os.path.exists(temp_dir):
                os.rmdir(temp_dir)
            
    except mysql.connector.Error as e:
        print("Error:", e)
    
    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'connection' in locals() and connection.is_connected():
            connection.close()
        print("MySQL connection closed.")
        return output_pdf_path

# # Example usage
# if __name__ == "__main__":
#     home_id = 1  # Example home_id
#     start_date = '2025-02-06'  # Example start date
#     end_date = '2025-02-07'  # Example end date
#     output_pdf_path = "energy_consumption_report.pdf"
    
#     generate_energy_report(home_id, start_date, end_date, output_pdf_path)




# Route to generate and download the report
@app.route('/generatereport')
def generate_report():
    home_id = request.args.get('home_id')
    start_date = request.args.get('start_date') 
    end_date = request.args.get('end_date') 
    # home_id = "1"
    # start_date = "2025-03-06T21:59:00.000" 
    # end_date = "2025-03-09T21:59:00.000" 

    print(start_date)
    print(end_date)
    try:
         
        # home_id = 1  # Example home ID
        # start_date = '2025-01-01'
        # end_date = '2025-12-31'


# Get the default Downloads folder path
        downloads_folder = Path.home() / "Downloads"

# Define the default PDF file path
        output_pdf_path = downloads_folder / "generated_report.pdf"
        # Generate the PDF file
        pdf_path = generate_energy_report(home_id, start_date, end_date, str(output_pdf_path))
        
        # Send the file to the browser for download
        # return send_file(pdf_path, as_attachment=True, download_name="generated_report.pdf")
    except Exception as e:
        return f"An error occurred: {str(e)}"
    
    if os.path.exists(pdf_path):
        response = Response(open(pdf_path, 'rb').read())
        response.headers['Content-Type'] = 'application/pdf'
        response.headers['Content-Disposition'] = 'attachment; filename=generated_report.pdf'
        return response
    else:
        return "File not found", 404
    





import mysql.connector
from mysql.connector import Error
from faker import Faker
import random
import json
from datetime import datetime, timedelta
import firebase_admin
from firebase_admin import credentials, auth, firestore

def Updatesql():
    def get_firebase_users():
        user_data = []
        try:
            page = auth.list_users()
            while page:
                for user in page.users:
                    firebase_id = user.uid  
                    user_name = user.display_name if user.display_name else f"User_{firebase_id[:6]}"
                    
                    # Fetch user role from Firestore
                    user_doc = db.collection('users').document(firebase_id).get()
                    role = user_doc.to_dict().get('role', 'user') if user_doc.exists else 'user'
                    
                    user_data.append((firebase_id, user_name, role))
                page = page.get_next_page()
        except Exception as e:
            print(f"Error fetching Firebase users: {e}")
        return user_data

    def get_existing_users(cursor):
        """Fetch existing users from MySQL database."""
        cursor.execute("SELECT firebase_id FROM User")
        return [row[0] for row in cursor.fetchall()]

    # Connect to MySQL
    try:
        
        connection = get_db_connection()

        if connection.is_connected():
            print("Connected to MySQL Server successfully!")
            cursor = connection.cursor()

            # Get all Firebase users
            firebase_users = get_firebase_users()

            if not firebase_users:
                print("No Firebase users found. Ensure Firebase is properly set up.")
                exit()
            else:
                print(f"Fetched {len(firebase_users)} users from Firebase.")

            # Get existing users from MySQL
            existing_users = get_existing_users(cursor)
            print(f"Found {len(existing_users)} existing users in MySQL database.")

            # Filter out new users
            new_firebase_users = [user for user in firebase_users if user[0] not in existing_users]
            print(f"Found {len(new_firebase_users)} new users to add.")

            if not new_firebase_users:
                print("No new users to add. Exiting.")
                exit()

            # Separate new users and admins
            new_users = [user for user in new_firebase_users if user[2] == 'User']
            new_admins = [user for user in new_firebase_users if user[2] == 'Admin']

            # Insert new users and admins into User table
            new_user_data = [(user[0], user[2]) for user in new_firebase_users]
            cursor.executemany("INSERT INTO User (firebase_id, role) VALUES (%s, %s)", new_user_data)
            connection.commit()
            print(f"{len(new_user_data)} new users inserted into User table.")

            # Retrieve user_id mapping for all users (including newly added)
            cursor.execute("SELECT id, firebase_id FROM User")
            user_id_mapping = {firebase_id: user_id for user_id, firebase_id in cursor.fetchall()}

            # Get existing home IDs for admin assignment
            cursor.execute("SELECT id, home_name FROM Homes WHERE role = 'Admin'")
            existing_homes = cursor.fetchall()
            existing_home_ids = [home[0] for home in existing_homes]
            
            # Start home_id counter after the last existing home
            home_id_counter = max(existing_home_ids) + 1 if existing_home_ids else 1

            # Assign each new admin to a unique home_id
            homes_data = []
            admin_home_ids = []
            
            for admin in new_admins:
                home_name = f"Home_{home_id_counter}"
                homes_data.append((home_name, user_id_mapping[admin[0]], admin[2]))
                admin_home_ids.append(home_id_counter)
                home_id_counter += 1

            # Assign new users to random home_ids (including existing ones for better distribution)
            all_admin_home_ids = existing_home_ids + admin_home_ids
            
            for user in new_users:
                home_id = random.choice(all_admin_home_ids)
                # Get home name if it's an existing home
                if home_id in existing_home_ids:
                    existing_home = next((home for home in existing_homes if home[0] == home_id), None)
                    home_name = existing_home[1] if existing_home else f"Home_{home_id}"
                else:
                    home_name = f"Home_{home_id}"
                
                homes_data.append((home_name, user_id_mapping[user[0]], user[2]))

            # Insert new homes data
            if homes_data:
                cursor.executemany("INSERT INTO Homes (home_name, user_id, role) VALUES (%s, %s, %s)", homes_data)
                connection.commit()
                print(f"{len(homes_data)} new entries inserted into Homes table.")

            # Only process new admin homes for appliance and energy data
            if new_admins:
                # Fetch new admin home_ids
                new_admin_user_ids = [user_id_mapping[admin[0]] for admin in new_admins]
                format_strings = ','.join(['%s'] * len(new_admin_user_ids))
                cursor.execute(f"SELECT id, user_id, home_name FROM Homes WHERE user_id IN ({format_strings}) AND role = 'Admin'", 
                            tuple(new_admin_user_ids))
                new_home_admin_ids = {row[1]: (row[0], row[2]) for row in cursor.fetchall()}
                
                print(f"Found {len(new_home_admin_ids)} new admin homes to populate with data.")

                # List of appliances and room names
                appliance_names = ['Smart Light', 'Air Conditioner', 'Smart Speaker', 'Smart TV']
                room_names = ['Living room', 'Bedroom 1', 'Bedroom 2', 'TV lobby','Kitchen','Bedroom 3']

                # Fetch new admin home_ids
                new_admin_home_ids = [home_id for user_id, (home_id, home_name) in new_home_admin_ids.items()]

                # Generate appliance energy data for new admin homes only
                appliance_energy_data = []

                # Dictionary to track device numbers per (home_id, appliance_name)
                device_number_tracker = {}

                appliance_energy_data = []
                for home_id in new_admin_home_ids:
                    
                    for room_name in room_names:
                        room_id = room_names.index(room_name) + 1  # Unique room ID
                        
                        for appliance_name in appliance_names:
                            appliance_id = appliance_names.index(appliance_name) + 1  # Unique appliance ID
                            
                            # Initialize device number tracking for this home + appliance type if not exists
                            if (home_id, appliance_name) not in device_number_tracker:
                                device_number_tracker[(home_id, appliance_name)] = 1  
                            
                            device_number = device_number_tracker[(home_id, appliance_name)]

                            # Simulate appliance energy consumption for the past 30 days, every hour
                            start_date = datetime.now() - timedelta(days=30)  
                            current_timestamp = start_date
                            
                            while current_timestamp <= datetime.now():
                                # Simulate energy consumption between 0.02 kWh to 0.3 kWh per hour
                                energy_consumed = round(random.uniform(0.02, 0.3), 3)

                                # Store data for batch insertion
                                appliance_energy_data.append((
                                    home_id,
                                    room_id,
                                    room_name,
                                    appliance_id,
                                    appliance_name,
                                    device_number,  # Unique device number for each appliance type in the home
                                    energy_consumed,
                                    current_timestamp
                                ))

                                # Increment by 1 hour
                                current_timestamp += timedelta(hours=1)

                            # Increment device number for the next instance of this appliance type in this home
                            device_number_tracker[(home_id, appliance_name)] += 1  

                # Insert appliance energy data for new admin homes
                if appliance_energy_data:
                    cursor.executemany("""
                        INSERT INTO appliancecontrolenergy_data 
                        (home_id, room_id, room_name, appliance_id, appliance_name, device_number, energy_consumed, timestamp)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    """, appliance_energy_data)
                    connection.commit()
                    print(f"Inserted {len(appliance_energy_data)} appliance energy records for new admin homes.")


            # for home_id in new_admin_home_ids:

            #     device_number = 1  # Reset device counter for each home_id
        
            #     for room_name in room_names:
            #         room_id = room_names.index(room_name) + 1  # Unique room ID
                    
            #         for appliance_name in appliance_names:
            #             appliance_id = appliance_names.index(appliance_name) + 1  # Unique appliance ID
                        
            #             # Simulate appliance energy consumption for the past 30 days, every hour
            #             start_date = datetime.now() - timedelta(days=30)  
            #             current_timestamp = start_date
                        
            #             while current_timestamp <= datetime.now():
            #                 # Simulate energy consumption between 0.02 kWh to 0.3 kWh per hour
            #                 energy_consumed = round(random.uniform(0.02, 0.3), 3)

            #                 # Store data for batch insertion
            #                 appliance_energy_data.append((
            #                     home_id,
            #                     room_id,
            #                     room_name,
            #                     appliance_id,
            #                     appliance_name,
            #                     device_number,  # Add device number here
            #                     energy_consumed,
            #                     current_timestamp
            #                 ))

            #                 # Increment by 1 hour
            #                 current_timestamp += timedelta(hours=1)

            #             device_number += 1  # Increment device number for next appliance

            # # Insert appliance energy data for new admin homes
            # if appliance_energy_data:
            #     cursor.executemany("""
            #             INSERT INTO appliancecontrolenergy_data 
            #             (home_id, room_id, room_name, appliance_id, appliance_name, device_number, energy_consumed, timestamp)
            #             VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            #         """, appliance_energy_data)
            #     connection.commit()
            #     print(f"Inserted {len(appliance_energy_data)} appliance energy records for new admin homes.")



                # Summarize hourly energy consumption for new admin homes only
            for home_id in new_admin_home_ids:
                cursor.execute("""
                        SELECT home_id, DATE(timestamp) AS date, HOUR(timestamp) AS hour, 
                            SUM(energy_consumed) AS total_energy_consumed
                        FROM appliancecontrolenergy_data
                        WHERE home_id = %s
                        GROUP BY home_id, date, hour
                        ORDER BY home_id, date, hour
                    """, (home_id,))

                summarized_energy_data = cursor.fetchall()
                energy_table_data = []

                for home_id, date, hour, total_energy_consumed in summarized_energy_data:
                    # Generate energy generated within ±10% variation
                    energy_generated = round(total_energy_consumed * random.uniform(0.9, 1.1), 3)
                        
                        # Create a timestamp with the correct hour
                    hourly_timestamp = f"{date} {hour}:00:00"
                        
                        # Append to batch insert list
                    energy_table_data.append((home_id, total_energy_consumed, energy_generated, hourly_timestamp))

                    # Insert energy data for this home
                if energy_table_data:
                    cursor.executemany("""
                            INSERT INTO energy_data (home_id, energy_consumed, energy_generated, timestamp)
                            VALUES (%s, %s, %s, %s)
                        """, energy_table_data)
                    connection.commit()
                    print(f"Inserted {len(energy_table_data)} energy data records for home_id {home_id}.")    

                # Generate challenge data for new admin homes only
                def generate_challenge_data(new_admin_home_ids):
                    challenges = [
                        "Set the AC to 24°C (75°F) for a week and lower cooling costs by 5-15%.",
                        "Use motion-activated smart lights for a week and reduce energy usage by 25-40%.",
                        "Unplug all non-essential devices overnight and save up to 1-2 kWh per week.",
                        "Limit smart speaker usage to essential commands only and reduce energy usage by 15% in a week."
                    ]
                    descriptions = [
                        "Try to cut down your energy consumption to save on your monthly bills.",
                        "Make sure that no appliances are in use during peak hours to reduce the grid load.",
                        "Increase the generation of clean energy by optimizing solar panel use.",
                        "Conduct an audit of your home appliances to identify inefficiencies."
                    ]
                    status_options = ["Completed", "Pending"]
                    tips = [
                        "Enable Energy-Saving Mode on your TV to reduce brightness and power usage.",
                        "Turn off the TV when not in use to avoid unnecessary power consumption.",
                        "Reduce the brightness of the TV and contrast settings to lower energy usage.",
                        "Use a smart power strip to cut power to the TV and connected devices when turned off.",
                        "Disable Quick Start Mode to prevent the TV from using power in standby mode.",
                        "Unplug the TV when going on vacation to eliminate phantom power usage.",
                        "Lower the volume on your smart speaker to reduce power consumption.",
                        "Turn off the microphone when not needed to prevent background processing.",
                        "Use voice commands to turn off connected appliances and save energy.",
                        "Schedule automatic downtime for the smart speaker during sleeping hours.",
                        "Use motion sensors to turn smart lights off when a room is unoccupied.",
                        "Dim smart lights when full brightness is not needed to save power.",
                        "Use LED smart bulbs instead of incandescent bulbs for higher efficiency.",
                        "Enable night mode to lower brightness and energy consumption in the evening.",
                        "Set the thermostat to an energy-efficient temperature (e.g., 24°C or 75°F).",
                        "Use a programmable thermostat to schedule cooling only when needed.",
                        "Clean or replace air filters regularly to maintain AC efficiency.",
                        "Close windows and doors while the AC is running to prevent cool air loss.",
                        "Use ceiling fans along with the AC to distribute cool air efficiently."
                    ]

                    challenge_data = []
                    for home_id in new_admin_home_ids:
                        # Get home name
                        cursor.execute("SELECT home_name FROM Homes WHERE id = %s", (home_id,))
                        result = cursor.fetchone()
                        home_name = result[0] if result else f"Home_{home_id}"
                        
                        challenge = random.choice(challenges)
                        description = random.choice(descriptions)
                        status = random.choice(status_options)
                        tips_selected = random.sample(tips, 10)  # Get 10 unique random tips
                        tips_selected_str = json.dumps(tips_selected)  # Convert list to JSON string

                        points_earned = random.randint(5, 20) if status == "Completed" else 0
                        completed_at = datetime.now().strftime('%Y-%m-%d %H:%M:%S') if status == "Completed" else None
                        created_at = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
                        updated_at = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

                        challenge_data.append(
                            (home_id, random.randint(1, 100), challenge, description, status, tips_selected_str, points_earned, completed_at, created_at, updated_at)
                        )

                    return challenge_data

                # Insert challenges for new admin homes
                challenge_data = generate_challenge_data(new_admin_home_ids)
                if challenge_data:
                    cursor.executemany(""" 
                        INSERT INTO ChallengeParticipants 
                        (home_id, challenge_id, challenge, description, status, tips, points_earned, completed_at, created_at, updated_at) 
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    """, challenge_data)
                    connection.commit()
                    print(f"Inserted {len(challenge_data)} challenge records for new admin homes.")
                
            else:
                print("No new admin homes to generate data for.")

    except Error as e:
        print("Error:", e)

    finally:
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'connection' in locals() and connection.is_connected():
            connection.close()
        print("MySQL connection closed.")
        return "Done";







@app.route('/updatesql')
def call():
    return Updatesql() 








# Connection route
@app.route('/connection')
def connect():
    statm = request.args.get('statm') 


    if statm is None:
        return jsonify({"error": "statm is missing"}), 400
    
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)

        cursor.execute(statm)


        if statm.strip().upper().startswith(("UPDATE", "INSERT", "DELETE")):
            print("update FOUND")
            connection.commit()
            return "done";




        results = cursor.fetchall()
        print(f"rows affected  {cursor.rowcount}")

        #cursor.execute("select * from appliancecontrolenergy_data WHERE slider_state = 0.68")  
        cursor.close()
        return jsonify(results)
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500




# Get energy data route
@app.route('/get_energy_data', methods=['GET'])
def get_energy_data():
    home_id = request.args.get('home_id')
    time_interval = request.args.get('time_interval')

    if not home_id or not home_id.isdigit():
        return jsonify({'error': 'Invalid home_id'}), 400
    
    end_date = datetime.now()
    
    time_intervals = {
        '6H': timedelta(hours=6),
        '24H': timedelta(hours=24),
        '1W': timedelta(weeks=1),
        '1M': timedelta(days=30),
        '3M': timedelta(days=90),
        '1Y': timedelta(days=365),
        '2Y': timedelta(days=730),
    }

    if time_interval not in time_intervals:
        return jsonify({'error': 'Invalid time interval'}), 400
    
    start_date = end_date - time_intervals[time_interval]

    connection = get_db_connection()
    cursor = connection.cursor()
    query = """
        SELECT timestamp, energy_consumed
        FROM energy_data
        WHERE home_id = %s AND timestamp BETWEEN %s AND %s
    """
    cursor.execute(query, (home_id, start_date, end_date))
    data = cursor.fetchall()
    
    formatted_data = [{'timestamp': row[0].strftime('%Y-%m-%d %H:%M:%S'), 'energy_consumed': row[1]} for row in data]

    cursor.close()
    return jsonify({'data': formatted_data})

# Run the app
if __name__ == '__main__':

    # with app.app_context():
    #     # Now you can safely call generate_energy_report() with the app context active
    #     home_id = 1  # Example home ID
    #     start_date = '2025-01-01'
    #     end_date = '2025-12-31'
    #     output_pdf_path = 'C:/Users/rosha/Downloads/generated_report.pdf'  
    #     generate_energy_report(home_id, start_date, end_date, output_pdf_path)
    # home_id = 1  # Example home_id
    # start_date = '2025-02-06'  # Example start date
    # end_date = '2025-02-07'  # Example end date
    # output_pdf_path = "energy_consumption_report.pdf"

    # generate_energy_report(home_id, start_date, end_date, output_pdf_path)
        #app.run(debug=True)
        app.run(host='0.0.0.0', port=5000, debug=True)