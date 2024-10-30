# Raspberry Pi : alphatronRPI.py
import threading
from picamera2 import Picamera2
import cv2
import socket
import RPi.GPIO as GPIO
import time
from adafruit_servokit import ServoKit

# ================================
# GPIO and Servo Motor Setup
# ================================

# Camera field of view
FRAME_WIDTH = 640
FRAME_HEIGHT = 480
HFOV = 109.3  # Raspberry Pi Camera Module 3 Wide Horizontal FOV in degrees
VFOV = 48.8   # Raspberry Pi Camera Module 3 Wide Vertical FOV in degrees

FRAME_CENTER_X = FRAME_WIDTH / 2
FRAME_CENTER_Y = FRAME_HEIGHT / 2

# --- GPIO Mode Configuration ---
DESIRED_MODE = GPIO.BCM  # Set to BCM to match current mode

# Check the current GPIO mode
current_mode = GPIO.getmode()

if current_mode is None:
    GPIO.setmode(DESIRED_MODE)
    print(f"GPIO mode set to {DESIRED_MODE} (BCM).")
elif current_mode != DESIRED_MODE:
    raise ValueError(f"GPIO mode already set to {current_mode}. Cannot set to {DESIRED_MODE}.")
else:
    print(f"GPIO mode is already set to {current_mode} (BCM).")

# --- Servo Motor 1 Configuration (GPIO18) ---
SERVO_PIN = 18  # BCM pin number 18 (BOARD pin number 12)
SERVO_MIN_DUTY = 2   # Duty cycle for 0 degrees
SERVO_MAX_DUTY = 11  # Duty cycle for 180 degrees

# Setup GPIO for Servo Motor 1
GPIO.setup(SERVO_PIN, GPIO.OUT)

# Initialize PWM for Servo Motor 1 at 50Hz
servo0 = GPIO.PWM(SERVO_PIN, 50)
servo0.start(0)  # Start PWM with 0% duty cycle

# --- Servo Motor 2 Configuration (ServoKit) ---
kit = ServoKit(channels=16, address=0x40)  # Adjust 'address' if necessary

# --- Relay Pin Setup for Shoot Command ---
relay_pin = 17  # Using GPIO17 pin

# Setup GPIO for relay pin
GPIO.setup(relay_pin, GPIO.OUT)  # Set relay pin to output mode
GPIO.output(relay_pin, GPIO.LOW)  # Initialize relay to off

# Shared variables for target positions
# Initialize with default values (no target)
target_positions = {'cx': FRAME_CENTER_X, 'cy': FRAME_CENTER_Y}
position_lock = threading.Lock()  # Lock for synchronizing access


def setServoPosGPIO(angle):
    """
    Moves the servo motor connected to GPIO18 to the specified angle.

    Parameters:
    angle (float): The target angle between 0 and 180 degrees
    """
    # Reverse the angle (180 - angle)
    reversed_angle = 180 - angle

    # Limit the reversed angle between 0 and 180 degrees
    reversed_angle = max(0, min(180, reversed_angle))

    # Calculate the duty cycle
    duty = SERVO_MIN_DUTY + (reversed_angle * (SERVO_MAX_DUTY - SERVO_MIN_DUTY) / 180.0)

    # Move the servo motor
    servo0.ChangeDutyCycle(duty)


def setServoPosServoKit(angle):
    """
    Moves the servo motor connected to ServoKit channel 0 to the specified angle.

    Parameters:
    angle (float): The target angle between 0 and 180 degrees
    """
    # Reverse the angle (180 - angle)
    reversed_angle = 180 - angle

    # Limit the reversed angle between 0 and 180 degrees
    reversed_angle = max(0, min(180, reversed_angle))

    # Set the angle for Servo Motor 2 (channel 0)
    kit.servo[0].angle = reversed_angle


def servo_control_thread():
    """
    Thread function to control the servo motors asynchronously.
    """
    prev_servo0_angle = None
    prev_servo1_angle = None

    while True:
        try:
            with position_lock:
                cx = target_positions['cx']
                cy = target_positions['cy']

            if cx is not None and cy is not None:
                # Calculate target angles for servos
                target_servo0_angle = ((cx - FRAME_CENTER_X) / FRAME_WIDTH) * HFOV + 90
                target_servo1_angle = ((cy - FRAME_CENTER_Y) / FRAME_HEIGHT) * VFOV + 90

                # Only update servo positions if there is a significant change
                if prev_servo0_angle is None or abs(target_servo0_angle - prev_servo0_angle) > 1:
                    setServoPosGPIO(target_servo0_angle)
                    prev_servo0_angle = target_servo0_angle

                if prev_servo1_angle is None or abs(target_servo1_angle - prev_servo1_angle) > 1:
                    setServoPosServoKit(target_servo1_angle)
                    prev_servo1_angle = target_servo1_angle

            time.sleep(0.1)  # Small delay to prevent CPU overutilization
            # Remove or comment out the following line
            # servo0.ChangeDutyCycle(0)
        except Exception as e:
            print(f"Exception in servo_control_thread: {e}")



def send_frame_via_socket(s, frame):
    try:
        frame = cv2.resize(frame, (640, 480))  # Resize the frame to 640x480
        encoded_frame = cv2.imencode('.jpg', frame, [int(cv2.IMWRITE_JPEG_QUALITY), 90])[1].tobytes()

        # Send the image size information
        frame_size = len(encoded_frame).to_bytes(4, byteorder='big')
        s.sendall(frame_size + encoded_frame)  # Send both size and image data
        print(f"Sent frame of size: {len(encoded_frame)} bytes")
    except Exception as e:
        print(f"Error sending frame: {e}")


def receive_ack_with_data(s):
    try:
        data = s.recv(4096)
        if not data:
            return None
        data_str = data.decode().strip()
        tokens = data_str.split(',')
        if len(tokens) != 4:
            print(f"Unexpected data format: {data_str}")
            return None
        target_id, cx, cy, shoot_value = tokens
        return {
            'id': target_id,
            'cx': cx,
            'cy': cy,
            'shoot_value': shoot_value
        }
    except socket.timeout:
        print("Socket timeout while waiting for data")
        return "TIMEOUT"
    except Exception as e:
        print(f"Error receiving data: {e}")
        return None


def execute_shoot_command():
    """
    Activates the relay to perform the shoot command.
    """
    n = 0.2  # Duration to activate the relay in seconds
    GPIO.output(relay_pin, GPIO.HIGH)  # Activate relay
    time.sleep(n)
    GPIO.output(relay_pin, GPIO.LOW)   # Deactivate relay
    print("Executed shoot command")


def main():
    # Start the servo control thread
    servo_thread = threading.Thread(target=servo_control_thread, daemon=True)
    servo_thread.start()

    # ================================
    # Camera and Networking Setup
    # ================================

    # Camera setup
    picam2 = Picamera2()

    main_config = {"format": "RGB888", "size": (640, 480)}
    camera_config = picam2.create_preview_configuration(main=main_config)
    picam2.configure(camera_config)
    picam2.set_controls({"FrameRate": 30.0})  # Set initial FPS to 30

    picam2.start()

    # Socket setup
    HOST = '192.168.1.1'  # Change to the server's IP address
    PORT = 5000           # Match the port number

    frame_transmission_paused = False  # Flag to control frame transmission

    # Establish socket connection
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((HOST, PORT))
        s.settimeout(5)  # Set a timeout of 5 seconds
        print(f"Connected to {HOST}:{PORT}")

        # Send initial frame
        frame = picam2.capture_array()
        send_frame_via_socket(s, frame)

        # Handle initial connection (ack)
        received_data = receive_ack_with_data(s)
        if received_data is None:
            print("No initial data received from server")
        else:
            print("Received initial data from server")

        while True:
            try:
                if frame_transmission_paused:
                    # Pause frame transmission
                    print("Frame transmission is paused, waiting before resuming...")
                    time.sleep(1)  # Wait for 1 second before trying again
                    frame_transmission_paused = False
                    continue

                # Capture frame
                frame = picam2.capture_array()
                # Send the frame to the server
                send_frame_via_socket(s, frame)

                # Wait until a response is received from the server
                received_data = receive_ack_with_data(s)

                if received_data == "TIMEOUT":
                    # When a timeout occurs, pause frame transmission
                    print("Timeout occurred, pausing frame transmission")
                    frame_transmission_paused = True
                    continue  # Skip to the next iteration to pause sending frames

                if received_data is None:
                    # When no valid data is received from the server
                    print("No valid data received from server")
                    continue

                else:
                    # Process the received data
                    target_id = received_data['id']
                    cx = received_data['cx']
                    cy = received_data['cy']
                    shoot_value = received_data['shoot_value']

                    if shoot_value == '1':
                        # Execute shoot command
                        execute_shoot_command()

                    if cx != "None" and cy != "None":
                        # Ensure cx and cy are integers
                        cx = int(cx)
                        cy = int(cy)
                        # Update the target positions for the servo control thread
                        with position_lock:
                            target_positions['cx'] = cx
                            target_positions['cy'] = cy
                        print(f"Tracking target ID {target_id} at position ({cx}, {cy})")
                    else:
                        # No valid centroid data
                        with position_lock:
                            target_positions['cx'] = FRAME_CENTER_X
                            target_positions['cy'] = FRAME_CENTER_Y
                        print("No valid target position received")

                    # Display the captured frame
                    cv2.imshow('Camera Feed', frame)
                    if cv2.waitKey(1) & 0xFF == ord('q'):
                        break

            except Exception as e:
                print(f"Error: {e}")
                break

    # Cleanup operations
    picam2.stop()
    cv2.destroyAllWindows()
    # Clean up GPIO settings
    servo0.stop()
    GPIO.cleanup()
    print("Connection closed")


if __name__ == '__main__':
    main()
