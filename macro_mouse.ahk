#Requires AutoHotkey v2.0
#SingleInstance Force

configFile := A_ScriptDir '\config.ini'
EnsureConfig(configFile)

global startHotkey := IniRead(configFile, 'Macro', 'start_hotkey', 'F6')
global stopHotkey := IniRead(configFile, 'Macro', 'stop_hotkey', 'F7')
global targetKey := IniRead(configFile, 'Macro', 'target_key', 'LButton')
global holdMs := Max(10, Integer(IniRead(configFile, 'Macro', 'hold_ms', '1000')))
global intervalMs := Max(0, Integer(IniRead(configFile, 'Macro', 'interval_ms', '250')))

global running := false
global registeredStartHotkey := ''
global registeredStopHotkey := ''

global mainGui := ''
global startHotkeyInput := ''
global stopHotkeyInput := ''
global targetKeyInput := ''
global holdMsInput := ''
global intervalMsInput := ''
global statusLabel := ''

global captureIncludeModifiers := false
global capturedValue := ''

CreateInterface()

Try {
    ApplyHotkeys(startHotkey, stopHotkey)
} Catch Error as err {
    MsgBox 'Erro ao registrar atalhos.`n`nDetalhe: ' err.Message, 'Macro Mouse', 'Iconx'
    ExitApp
}

UpdateStatusLabel()
mainGui.Show('AutoSize')

CreateInterface() {
    global mainGui
    global startHotkeyInput, stopHotkeyInput
    global targetKeyInput, holdMsInput, intervalMsInput
    global statusLabel
    global startHotkey, stopHotkey, targetKey, holdMs, intervalMs

    mainGui := Gui('+AlwaysOnTop', 'Macro Mouse')
    mainGui.SetFont('s10', 'Segoe UI')

    mainGui.AddText('xm ym+10 w130', 'Atalho iniciar:')
    startHotkeyInput := mainGui.AddEdit('x+10 w160', startHotkey)
    recordStartButton := mainGui.AddButton('x+8 w90', 'Gravar')
    recordStartButton.OnEvent('Click', RecordStartHotkey)

    mainGui.AddText('xm y+14 w130', 'Atalho parar:')
    stopHotkeyInput := mainGui.AddEdit('x+10 w160', stopHotkey)
    recordStopButton := mainGui.AddButton('x+8 w90', 'Gravar')
    recordStopButton.OnEvent('Click', RecordStopHotkey)

    mainGui.AddText('xm y+14 w130', 'Tecla/Botao:')
    targetKeyInput := mainGui.AddEdit('x+10 w160', targetKey)
    recordTargetButton := mainGui.AddButton('x+8 w90', 'Gravar')
    recordTargetButton.OnEvent('Click', RecordTargetKey)

    mainGui.AddText('xm y+14 w130', 'Tempo segurar (ms):')
    holdMsInput := mainGui.AddEdit('x+10 w160 Number', holdMs)

    mainGui.AddText('xm y+14 w130', 'Intervalo (ms):')
    intervalMsInput := mainGui.AddEdit('x+10 w160 Number', intervalMs)

    saveButton := mainGui.AddButton('xm y+20 w150', 'Salvar e aplicar')
    saveButton.OnEvent('Click', SaveAndApply)

    startButton := mainGui.AddButton('x+10 w80', 'Iniciar')
    startButton.OnEvent('Click', StartMacro)

    stopButton := mainGui.AddButton('x+10 w80', 'Parar')
    stopButton.OnEvent('Click', StopMacro)

    statusLabel := mainGui.AddText('xm y+16 w620', 'Status: Parado')

    helpText := 'Clique em Gravar e pressione a tecla desejada (Esc cancela).'
    mainGui.AddText('xm y+6 w620', helpText)

    examplesText := 'Exemplos: LButton, RButton, MButton, Space, Enter, F6, ^!s'
    mainGui.AddText('xm y+4 w620', examplesText)

    mainGui.OnEvent('Close', GuiClose)
}

GuiClose(*) {
    ExitApp
}

RecordStartHotkey(*) {
    global startHotkeyInput

    value := CaptureInput(true, 'Pressione a combinacao para INICIAR...')
    if value != '' {
        startHotkeyInput.Value := value
    }
}

RecordStopHotkey(*) {
    global stopHotkeyInput

    value := CaptureInput(true, 'Pressione a combinacao para PARAR...')
    if value != '' {
        stopHotkeyInput.Value := value
    }
}

RecordTargetKey(*) {
    global targetKeyInput

    value := CaptureInput(false, 'Pressione a tecla/botao para o clique...')
    if value != '' {
        targetKeyInput.Value := value
    }
}

CaptureInput(includeModifiers, promptText) {
    global captureIncludeModifiers, capturedValue

    captureIncludeModifiers := includeModifiers
    capturedValue := ''

    ToolTip(promptText)

    ih := InputHook('L0')
    ih.KeyOpt('{All}', 'N')
    ih.OnKeyDown := CaptureOnKeyDown
    ih.Start()
    ih.Wait()

    ToolTip()
    return capturedValue
}

CaptureOnKeyDown(ih, vk, sc) {
    global captureIncludeModifiers, capturedValue

    keyName := GetKeyName(Format('vk{:X}', vk))
    if keyName = '' {
        keyName := GetKeyName(Format('sc{:X}', sc))
    }

    if keyName = '' {
        return
    }

    if keyName = 'Escape' {
        capturedValue := ''
        ih.Stop()
        return
    }

    if IsModifierKey(keyName) {
        return
    }

    if captureIncludeModifiers {
        capturedValue := GetPressedModifiers() keyName
    } else {
        capturedValue := keyName
    }

    ih.Stop()
}

GetPressedModifiers() {
    mods := ''

    if GetKeyState('Ctrl', 'P') {
        mods .= '^'
    }
    if GetKeyState('Alt', 'P') {
        mods .= '!'
    }
    if GetKeyState('Shift', 'P') {
        mods .= '+'
    }
    if GetKeyState('LWin', 'P') || GetKeyState('RWin', 'P') {
        mods .= '#'
    }

    return mods
}

IsModifierKey(keyName) {
    normalized := StrLower(keyName)
    return normalized = 'ctrl'
        || normalized = 'lctrl'
        || normalized = 'rctrl'
        || normalized = 'alt'
        || normalized = 'lalt'
        || normalized = 'ralt'
        || normalized = 'shift'
        || normalized = 'lshift'
        || normalized = 'rshift'
        || normalized = 'lwin'
        || normalized = 'rwin'
}

SaveAndApply(*) {
    global configFile
    global startHotkey, stopHotkey, targetKey, holdMs, intervalMs
    global startHotkeyInput, stopHotkeyInput, targetKeyInput, holdMsInput, intervalMsInput

    newStart := Trim(startHotkeyInput.Value)
    newStop := Trim(stopHotkeyInput.Value)
    newTarget := Trim(targetKeyInput.Value)

    Try {
        if newStart = '' {
            throw Error('Atalho de iniciar nao pode ficar vazio.')
        }
        if newStop = '' {
            throw Error('Atalho de parar nao pode ficar vazio.')
        }
        if StrLower(newStart) = StrLower(newStop) {
            throw Error('Atalhos de iniciar e parar nao podem ser iguais.')
        }
        if newTarget = '' {
            throw Error('Tecla/Botao nao pode ficar vazio.')
        }

        newHold := ParseIntWithMin(holdMsInput.Value, 10, 'Tempo de segurar')
        newInterval := ParseIntWithMin(intervalMsInput.Value, 0, 'Intervalo')

        ApplyHotkeys(newStart, newStop)

        startHotkey := newStart
        stopHotkey := newStop
        targetKey := newTarget
        holdMs := newHold
        intervalMs := newInterval

        WriteConfig(configFile, startHotkey, stopHotkey, targetKey, holdMs, intervalMs)
        UpdateStatusLabel()
        MsgBox 'Configuracao salva e aplicada com sucesso.', 'Macro Mouse', 'Iconi'
    } Catch Error as err {
        MsgBox 'Falha ao salvar configuracao.`n`n' err.Message, 'Macro Mouse', 'Iconx'
    }
}

ApplyHotkeys(newStart, newStop) {
    global registeredStartHotkey, registeredStopHotkey

    if registeredStartHotkey != '' {
        Try Hotkey(registeredStartHotkey, 'Off')
    }

    if registeredStopHotkey != '' {
        Try Hotkey(registeredStopHotkey, 'Off')
    }

    Hotkey(newStart, StartMacro)
    Hotkey(newStop, StopMacro)

    registeredStartHotkey := newStart
    registeredStopHotkey := newStop

    A_IconTip := 'Macro Mouse (' newStart ' iniciar | ' newStop ' parar)'
}

ParseIntWithMin(rawValue, minValue, fieldName) {
    valueText := Trim(rawValue)

    Try parsed := Integer(valueText)
    Catch {
        throw Error(fieldName ' invalido.')
    }

    if parsed < minValue {
        throw Error(fieldName ' deve ser maior ou igual a ' minValue '.')
    }

    return parsed
}

StartMacro(*) {
    global running

    if running {
        return
    }

    running := true
    UpdateStatusLabel()
    SetTimer(MacroLoop, -1)
}

StopMacro(*) {
    global running

    running := false
    UpdateStatusLabel()
}

MacroLoop() {
    global running, targetKey, holdMs, intervalMs

    if !running {
        return
    }

    Try {
        SendEvent('{' targetKey ' down}')
        Sleep(holdMs)
        SendEvent('{' targetKey ' up}')
    } Catch Error as err {
        running := false
        UpdateStatusLabel()
        MsgBox 'Erro durante execucao do macro.`n`n' err.Message, 'Macro Mouse', 'Iconx'
        return
    }

    if !running {
        return
    }

    if intervalMs > 0 {
        Sleep(intervalMs)
    }

    SetTimer(MacroLoop, -1)
}

UpdateStatusLabel() {
    global statusLabel, running
    global startHotkey, stopHotkey, targetKey, holdMs, intervalMs

    state := running ? 'Rodando' : 'Parado'
    statusLabel.Value := 'Status: ' state
        . ' | Inicio: ' startHotkey
        . ' | Parar: ' stopHotkey
        . ' | Tecla: ' targetKey
        . ' | Hold: ' holdMs ' ms'
        . ' | Intervalo: ' intervalMs ' ms'
}

WriteConfig(path, startKey, stopKey, keyTarget, holdValue, intervalValue) {
    IniWrite(startKey, path, 'Macro', 'start_hotkey')
    IniWrite(stopKey, path, 'Macro', 'stop_hotkey')
    IniWrite(keyTarget, path, 'Macro', 'target_key')
    IniWrite(holdValue, path, 'Macro', 'hold_ms')
    IniWrite(intervalValue, path, 'Macro', 'interval_ms')
}

EnsureConfig(path) {
    if FileExist(path) {
        return
    }

    IniWrite('F6', path, 'Macro', 'start_hotkey')
    IniWrite('F7', path, 'Macro', 'stop_hotkey')
    IniWrite('LButton', path, 'Macro', 'target_key')
    IniWrite('1000', path, 'Macro', 'hold_ms')
    IniWrite('250', path, 'Macro', 'interval_ms')
}
