
import pymysql

try:
    connection = pymysql.connect(
        host="localhost",
        user="root",
        password="Admin@123",
        database="cricket_wc2023",
        port=3306
    )

    print("MySQL connection successful!")

    cursor = connection.cursor()
    cursor.execute("SELECT DATABASE()")

    print("Connected database:", cursor.fetchone()[0])

    cursor.execute("SHOW TABLES")
    print("\nAvailable tables:")

    for table in cursor.fetchall():
        print(table[0])

    cursor.close()
    connection.close()

except pymysql.MySQLError as error:
    print("MySQL connection failed:", error)
