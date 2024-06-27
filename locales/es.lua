local Translations = {
    lang1 = 'Abrir menú',
    lang2 = 'Menú de despacho de abogados',
    lang3 = 'Menú del jefe',
    lang4 = 'abrir el menú del jefe',
    lang5 = 'Alternar servicio',
    lang6 = 'Armería',
    lang7 = 'abre la armería',
    lang8 = 'Papelera',
    lang9 = 'para elementos que ya no son necesarios',
    lang10 = 'No autorizado',
    lang11 = 'Armería de la Oficina Legal',
    lang12 = 'Alerta policial ',
    lang13 = 'Fallo',
    lang14 = 'no puedes esposar a alguien en un vehículo',
    lang15 = 'Se necesitan esposas',
    lang16 = 'no tienes esposas',
    lang17 = '¡No hay nadie cerca!',
    lang18 = '¡Estás esposado!',
    lang19 = 'pero puedes caminar',
    lang20 = 'Jugador de la cárcel (solo ley)',
    lang21 = 'ID del jugador',
    lang22 = 'Tiempo que tienen para estar en la cárcel',
    lang23 = 'Tiempo de cárcel no válido',
    lang24 = 'el tiempo de cárcel debe ser superior a 0',
    lang25 = 'Enviado a la cárcel por ',
    lang26 = 'Jugador brazalete (solo lawman)',
    lang27 = 'Jugador de escolta (solo lawman)',
    lang28 = 'El jugador no está esposado ni muerto',
    lang29 = '¡Estás sin esposas!',
    lang30 = '¡No es un rango lo suficientemente alto!'
}


if GetConvar('rsg_locale', 'en') == 'es' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end