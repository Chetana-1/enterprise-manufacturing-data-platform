import psycopg2
import random
import time
from datetime import datetime


# ==============================
# DATABASE CONFIGURATION
# ==============================

DB_HOST = "localhost"
DB_PORT = 5432
DB_NAME = "DA-1"
DB_USER = "postgres"
DB_PASSWORD = "Back@1304"


# ==============================
# GENERATOR CONFIGURATION
# ==============================

MACHINES_MIN = 5
MACHINES_MAX = 10

# Generate one batch every 60 seconds
INTERVAL_SECONDS = 60


# ==============================
# DATABASE CONNECTION
# ==============================

def connect_database():
    return psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD
    )


# ==============================
# GET NEXT BATCH ID
# ==============================

def get_next_batch_id(cursor):

    cursor.execute("""
        SELECT batch_id
        FROM bronze.iot_manufacturing_realtime
        WHERE batch_id LIKE 'REALTIME_%'
        ORDER BY batch_id DESC
        LIMIT 1;
    """)

    result = cursor.fetchone()

    if result is None:
        return "REALTIME_003"

    last_batch = result[0]

    try:
        number = int(last_batch.split("_")[1])
        return f"REALTIME_{number + 1:03d}"

    except (ValueError, IndexError):
        return "REALTIME_003"


# ==============================
# GENERATE SENSOR DATA
# ==============================

def generate_sensor_data(machine_id):

    # Normal sensor values
    temperature = round(random.uniform(65, 80), 2)
    vibration = round(random.uniform(0.20, 0.70), 2)
    humidity = round(random.uniform(50, 70), 2)
    pressure = round(random.uniform(100.5, 102.0), 2)
    energy = round(random.uniform(70, 100), 2)

    machine_status = random.choice([0, 1, 1, 1, 1, 2])

    anomaly = False
    failure_type = None

    downtime_risk = round(random.uniform(0.05, 0.25), 2)
    maintenance_required = False

    remaining_life = round(random.uniform(100, 200), 2)

    # Occasionally create an anomaly
    if random.random() < 0.10:

        anomaly = True

        temperature = round(random.uniform(85, 100), 2)
        vibration = round(random.uniform(0.80, 1.20), 2)
        energy = round(random.uniform(100, 130), 2)

        downtime_risk = round(random.uniform(0.60, 0.95), 2)

        maintenance_required = True

        remaining_life = round(random.uniform(20, 80), 2)

        failure_type = random.choice([
            "Overheating",
            "High Vibration",
            "Mechanical Failure"
        ])

        machine_status = 2

    return (
        machine_id,
        temperature,
        vibration,
        humidity,
        pressure,
        energy,
        machine_status,
        anomaly,
        remaining_life,
        failure_type,
        downtime_risk,
        maintenance_required
    )


# ==============================
# INSERT DATA
# ==============================

def generate_batch():

    connection = None

    try:

        connection = connect_database()
        cursor = connection.cursor()

        batch_id = get_next_batch_id(cursor)

        timestamp = datetime.now()

        number_of_machines = random.randint(
            MACHINES_MIN,
            MACHINES_MAX
        )

        # Randomly select machines 1–50
        machines = random.sample(
            range(1, 51),
            number_of_machines
        )

        print("\n----------------------------------------")
        print("Generating IoT batch")
        print("Batch ID:", batch_id)
        print("Timestamp:", timestamp)
        print("Machines:", machines)

        for machine_id in machines:

            data = generate_sensor_data(machine_id)

            cursor.execute("""
                INSERT INTO bronze.iot_manufacturing_realtime(
                    timestamp,
                    machine_id,
                    temperature,
                    vibration,
                    humidity,
                    pressure,
                    energy_consumption,
                    machine_status,
                    anomaly_flag,
                    predicted_remaining_life,
                    failure_type,
                    downtime_risk,
                    maintenance_required,
                    load_timestamp,
                    source_file,
                    batch_id
                )
                VALUES (
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    %s,
                    CURRENT_TIMESTAMP,
                    %s,
                    %s
                );
            """, (
                timestamp,
                data[0],
                data[1],
                data[2],
                data[3],
                data[4],
                data[5],
                data[6],
                data[7],
                data[8],
                data[9],
                data[10],
                data[11],
                "iot_realtime_generator.py",
                batch_id
            ))

        connection.commit()

        print(
            f"SUCCESS: Inserted {number_of_machines} "
            f"records into bronze.iot_manufacturing_realtime"
        )

        cursor.close()

    except Exception as error:

        print("ERROR:", error)

        if connection:
            connection.rollback()

    finally:

        if connection:
            connection.close()


# ==============================
# CONTINUOUS GENERATOR
# ==============================

def main():

    print("========================================")
    print("EMDP IoT REALTIME DATA GENERATOR")
    print("========================================")
    print("Database:", DB_NAME)
    print("Table: bronze.iot_manufacturing")
    print("Interval:", INTERVAL_SECONDS, "seconds")
    print("Press CTRL+C to stop.")
    print("========================================")

    while True:

        generate_batch()

        print(
            f"Waiting {INTERVAL_SECONDS} seconds "
            "for the next batch..."
        )

        time.sleep(INTERVAL_SECONDS)


if __name__ == "__main__":
    main()