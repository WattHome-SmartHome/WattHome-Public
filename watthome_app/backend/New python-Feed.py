import mysql.connector
from mysql.connector import Error
from faker import Faker
import random
import json
from datetime import datetime, timedelta
import firebase_admin
from firebase_admin import credentials, auth, firestore

# Initialize Firebase Admin SDK
cred = credentials.Certificate(r"") # Add your own key file here
firebase_admin.initialize_app(cred)

# Initialize Firestore
db = firestore.client()

def get_firebase_users():
    """Fetch all Firebase users along with their roles from Firestore."""
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
    connection = mysql.connector.connect(
        host='localhost',        
        user='root',             
        password='password',   
        database='watthome', 
        port=3306,    
        charset='utf8mb4',
        collation='utf8mb4_unicode_ci'
    )

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