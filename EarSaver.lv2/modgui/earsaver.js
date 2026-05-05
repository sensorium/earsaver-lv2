function(event, funcs) {
    var led = event.icon.find('.earsaver-mute-led')[0];

    if (event.type === 'start') {
        if (led) led.classList.remove('active');

        return;
    }

    if (event.symbol === 'muting') {
        if (led) led.classList.toggle('active', event.value > 0.5);
        return;
    }
}
