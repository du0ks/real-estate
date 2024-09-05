from pynput import keyboard
from pynput.keyboard import Key, Controller
import time

# Initialize the controller
keyboard_controller = Controller()

# Flag to indicate if the key combination has been activated
activated = False

def press_key_combination():
    # Press <cmd>+A
    with keyboard_controller.pressed(Key.cmd):
        keyboard_controller.press('a')
        keyboard_controller.release('a')
    time.sleep(0.1)

    # Press <cmd>+C
    with keyboard_controller.pressed(Key.cmd):
        keyboard_controller.press('c')
        keyboard_controller.release('c')
    time.sleep(0.1)

    # Press <cmd>+<tab>
    with keyboard_controller.pressed(Key.cmd):
        keyboard_controller.press(Key.tab)
        keyboard_controller.release(Key.tab)
    time.sleep(0.1)

    # Press <cmd>+<arrow down>
    with keyboard_controller.pressed(Key.cmd):
        keyboard_controller.press(Key.down)
        keyboard_controller.release(Key.down)
    time.sleep(0.1)

    # Press <enter>
    keyboard_controller.press(Key.enter)
    keyboard_controller.release(Key.enter)
    time.sleep(0.1)

    # Press <cmd>+V
    with keyboard_controller.pressed(Key.cmd):
        keyboard_controller.press('v')
        keyboard_controller.release('v')
    time.sleep(0.1)

    # Press <cmd>+<tab>
    with keyboard_controller.pressed(Key.cmd):
        keyboard_controller.press(Key.tab)
        keyboard_controller.release(Key.tab)
    time.sleep(0.1)
    # Press <cmd>+W
    with keyboard_controller.pressed(Key.cmd):
        keyboard_controller.press('w')
        keyboard_controller.release('w')
    time.sleep(0.1)

def on_activate():
    global activated
    if not activated:
        press_key_combination()
        activated = True

# The combination to check
COMBINATION = {Key.cmd, Key.alt, Key.f9}

# The currently active modifiers
current = set()

def on_press(key):
    if any([key in COMBINATION]):
        current.add(key)
    if all(k in current for k in COMBINATION):
        on_activate()

def on_release(key):
    global activated
    try:
        current.remove(key)
        if key in COMBINATION:
            activated = False
    except KeyError:
        pass

# Set up the listener
with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
    listener.join()