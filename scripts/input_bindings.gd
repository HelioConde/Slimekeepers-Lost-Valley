extends RefCounted
## Cria as entradas em tempo de execucao apenas se o projeto ainda nao as possuir.
## Se voce configurar as mesmas acoes no Input Map do editor, nao serao sobrescritas.

static func install() -> void:
    _add_keyboard_action("move_left", [KEY_A, KEY_LEFT])
    _add_keyboard_action("move_right", [KEY_D, KEY_RIGHT])
    _add_keyboard_action("move_up", [KEY_W, KEY_UP])
    _add_keyboard_action("move_down", [KEY_S, KEY_DOWN])
    _add_keyboard_action("run", [KEY_SHIFT])
    _add_keyboard_action("dash", [KEY_SPACE])

    _add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
    _add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
    _add_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
    _add_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
    _add_joy_button("run", JOY_BUTTON_RIGHT_SHOULDER)
    _add_joy_button("dash", JOY_BUTTON_A)


static func _add_keyboard_action(action: StringName, keys: Array) -> void:
    if InputMap.has_action(action):
        return
    InputMap.add_action(action, 0.22)
    for key in keys:
        var event := InputEventKey.new()
        event.physical_keycode = key
        InputMap.action_add_event(action, event)


static func _add_joy_axis(action: StringName, axis: int, direction: float) -> void:
    var event := InputEventJoypadMotion.new()
    event.axis = axis
    event.axis_value = direction
    if not InputMap.action_has_event(action, event):
        InputMap.action_add_event(action, event)


static func _add_joy_button(action: StringName, button_index: int) -> void:
    var event := InputEventJoypadButton.new()
    event.button_index = button_index
    if not InputMap.action_has_event(action, event):
        InputMap.action_add_event(action, event)
