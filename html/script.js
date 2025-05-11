let raceId = 0;
let racePasword = '';
let alias = '';
let raceCreated = false;
let currentTrackId = 0;
let currentIdentifier = '';

window.addEventListener("message", function (e) {
    e = e.data;
    switch (e.type) {
        case "open":
            return openMenu(e)
        case "setPropsData":
            return setPropsData(e)
        case "update":
            return update(e)
        case "updateRaceData":
            return updateRaceData(e)
        case "close":
            return $("body , .hud").fadeOut(500);
        default:
            return;
    }
});

let raceData = null;
let interval = null;
let milliseconds = 999;
let previousCheckpointTime = null;
let previousLapTime = null;

function updateRaceData(data) {
    let currentGroupIndex = Math.floor((data.currentCheckpoint - 1) / 4);

    for (let i = 0; i < data.groupedCheckpointTimes.length; i++) {
        const groupData = data.groupedCheckpointTimes[i];
        const formattedTime = newFormatTime(groupData.totalTime, 0);
        const sectionElement = $(`.section:eq(${i})`);
        sectionElement.text(formattedTime);

        if (i < currentGroupIndex) {
            sectionElement.css("background-color", "rgba(255, 0, 0, 0.8)"); // Kırmızı
        } else if (i === currentGroupIndex) {
            sectionElement.css("background-color", "rgba(32, 74, 137,0.8)"); // Mavi
        } else {
            sectionElement.css("background-color", ""); // Varsayılan
        }
    }


    raceData = data;
    $('.hud , body').show();
    $('.tablet').hide();
    $('#laps').text(data.lap + " / " + data.totalLaps);
    $('#checkpoint').text(data.currentCheckpoint + " / " + data.totalCheckpoints);
    $('#racetime').text(newFormatTime(data.time, milliseconds));
    $('#current-lap').text(newFormatTime(data.lapTime, milliseconds));

    if (interval === null) {
        interval = setInterval(updateMilliseconds, 1);
    }

    $('.players-box').empty();
    $.each(data.racePositions, function (i, v) {
        let itemClass = "item";
        let aliasStyle = "";

        if (v.alias.alias == data.myAlias) {
            itemClass += " my-alias";
            aliasStyle = 'style="background-color: #2361ae;color: #c6e8ff;"';
            v.timeDifference = "0.000";
        }

        $('.players-length').text(data.racePositions.length + " players");
        $('.players-box').append(
            `<div class="${itemClass}">
                <div ${aliasStyle} class="number">${i + 1}</div>
                <div class="alias" ${aliasStyle}>${v.alias.alias}</div>
                <div ${aliasStyle} class="race-time">${v.timeDifference}</div>
                <div ${aliasStyle} class="left-box"></div>
            </div>`
        );
    });

    if (data.bestLapTime !== undefined) {
        if (data.bestLapTime !== previousLapTime) {
            const randomMilliseconds = Math.floor(Math.random() * 1000);
            $('#lap-time').text(newFormatTime(data.bestLapTime, randomMilliseconds));
            previousLapTime = data.bestLapTime
        }
    }


    if (data.checkpointTime !== previousCheckpointTime) {
        const randomMilliseconds = Math.floor(Math.random() * 1000);
        $('#current-lap-delta').text(newFormatTime(data.checkpointTime, randomMilliseconds));
        previousCheckpointTime = data.checkpointTime;
    }
}

function newFormatTime(timeInSeconds, milliseconds) {
    const minutes = Math.floor(timeInSeconds / 60);
    const seconds = Math.floor(timeInSeconds % 60);
    const formattedMinutes = minutes.toString().padStart(2, '0');
    const formattedSeconds = seconds.toString().padStart(2, '0');
    const formattedMilliseconds = milliseconds.toString().padStart(3, '0');
    return `${formattedMinutes}:${formattedSeconds}:${formattedMilliseconds}`;
}

function formatTimeWithoutMilliseconds(timeInSeconds) {
    const minutes = Math.floor(timeInSeconds / 60);
    const seconds = Math.floor(timeInSeconds % 60);

    const formattedMinutes = minutes.toString().padStart(2, '0');
    const formattedSeconds = seconds.toString().padStart(2, '0');
    return `${formattedMinutes}:${formattedSeconds}:000`;
}

function updateMilliseconds() {
    if (milliseconds === 0) {
        if (raceData) {
            raceData.time -= 1;
        }
        milliseconds = 999;
    } else {
        milliseconds -= 1;
    }
    if (raceData) {
        $('#racetime').text(newFormatTime(raceData.time, milliseconds));
        $('#current-lap').text(newFormatTime(raceData.lapTime, milliseconds));
    }
}


function openMenu(data) {
    alias = data.alias || '';
    racePasword = '';
    raceCreated = data.raceCreated || false;
    tracks = data['tracks'] || [];
    allAlias = data['allAlias'] || [];
    currentIdentifier = data.identifier || '';

    $('.logo2').attr('src', data.ServerLogo);

    if (raceCreated) {
        $('.create-track-open').html('Edit Track');
    } else {
        $('.create-track-open').html('Create Track');
    }

    $("body , .ladder-page , .cls-btn").fadeIn(500);
    $('.hud').hide();
    $('.tablet').css('display', 'flex');
    $('.tracks-page , .create-page , .login-page , .view-page , .create-track-page , .race-page , .racer-ladder').hide();
    $('.tracks-list , .rating-list').empty();

    $.each(tracks, function (i, v) {
        let trackData = v.track_data;

        if (trackData && trackData.eventName && trackData.type && trackData.distance && trackData.createTime) {
            $('.tracks-list').append(`
                <div data-id=${v.id} id="tracks-item" class="item">
                    <div class="name">${trackData.eventName}</div>
                    <div style="left: 25%;width: 1%;" class="name">${trackData.type}</div>
                    <div style="left: 42%;width: 1%;" class="name">${trackData.distance}mi</div>
                    <div style="left: 55.5%;width: 1%;" class="name">${formatDate(trackData.createTime)}</div>
                    <div data-page="create-page" data-id="${v.id}" class="view-button">Create</div>
                </div>
            `);
        } else {
        }
    });
    var itemsPerPage = 8;
    var currentPage = 0;
    var allAliasArray = Object.values(allAlias);
    var filteredAliasArray = allAliasArray;
    function renderPage(page, aliasArray) {
        $('.rating-list').empty();

        aliasArray.sort(function (a, b) {
            let ratingA = (a.data.length > 0 && a.data[0].rating) ? a.data[0].rating : 0;
            let ratingB = (b.data.length > 0 && b.data[0].rating) ? b.data[0].rating : 0;

            return ratingB - ratingA;
        });

        var start = page * itemsPerPage;
        var end = start + itemsPerPage;
        var items = aliasArray.slice(start, end);
        $.each(items, function (i, v) {
            var data = v.data;

            $.each(data, function (x, y) {
                var rating = y.rating !== undefined ? y.rating : 'N/A';
                var alias = y.alias !== undefined ? y.alias : 'Unknown';
                var vehicle = y.vehicle !== undefined ? y.vehicle : 'Unknown';
                var engine = y.engine !== undefined ? y.engine : 'Unknown';
                var transmission = y.transmission !== undefined ? y.transmission : 'Unknown';
                var turboSize = y.turboSize !== undefined ? y.turboSize + 'mm' : 'Unknown';

                $('.rating-list').append(`
                    <div class="item">
                        <div class="name">${rating}</div>
                        <div class="name" style="left: 15%;">${alias}</div>
                        <div class="name" style="left: 30.5%;">${vehicle}</div>
                        <div class="name" style="left: 45.5%;">${engine}</div>
                        <div class="name" style="left: 60.5%;">${transmission}</div>
                        <div class="name" style="left: 95%;">${turboSize}</div>
                    </div>
                `);
            });
        });

        $('.page-number').text(`${page + 1}`);

        $('.prev-page').prop('disabled', currentPage === 0);
        $('.next-page').prop('disabled', currentPage >= Math.ceil(aliasArray.length / itemsPerPage) - 1);
    }

    renderPage(currentPage, filteredAliasArray);

    $('.prev-page').click(function () {
        if (currentPage > 0) {
            currentPage--;
            renderPage(currentPage, filteredAliasArray);
        }
    });

    $('.next-page').click(function () {
        if (currentPage < Math.ceil(filteredAliasArray.length / itemsPerPage) - 1) {
            currentPage++;
            renderPage(currentPage, filteredAliasArray);
        }
    });

    $('.alias-search').on('keyup', function () {
        var searchTerm = $(this).val().toLowerCase();
        filteredAliasArray = allAliasArray.filter(function (item) {
            return item.data.some(function (data) {
                return data.alias.toLowerCase().includes(searchTerm);
            });
        });
        currentPage = 0;
        renderPage(currentPage, filteredAliasArray);
    });

    $('.active-list, .pending-list , .completed-list').empty();
    $.each(data['races'], function (i, v) {
        if (v.startControl) {
            $('.active-list').append(`
                <div class="item">
                  <div class="name">${v.eventName}</div>
                  <div style="left: 42%;width: 1%;" class="name">Ground Zero</div>
                  <div style="left: 55.5%;width: 1%;" class="name">Open</div>
                  <div style="left: 62.5%;width: 1%;" class="name">Lap</div>
                  <div style="left: 69.5%;width: 1%;" class="name">$0.00</div>
                  <div style="left: 77%;width: 1%;" class="name">3</div>
                  <div style="left: 83.5%;width: 1%;" class="name">8.49mi</div>
                  <div class="view-button">View</div>
                </div>
            `);
        } else {

            if (v.completed) {
                $('.completed-list').append(`
                    <div class="item" data-password="${v.password}" data-id="${v.id}" data-players="${encodeURIComponent(JSON.stringify(v.players))}"  data-event-name="${v.eventName}"  data-vehicle-class="${v.vehicleClass}"  data-type="${v.type}"  data-buy-in="${v.buyIn}"  data-laps="${v.laps}"  data-distance="${v.distance}">
                        <div class="name">${v.eventName}</div>
                        <div style="left: 42%; width: 1%;" class="name">Ground Zero</div>
                        <div style="left: 55.5%; width: 1%;" class="name">${v.vehicleClass}</div>
                        <div style="left: 62.5%; width: 1%;" class="name">${v.type}</div>
                        <div style="left: 69.5%; width: 1%;" class="name">$${v.buyIn}</div>
                        <div style="left: 77%; width: 1%;" class="name">${v.laps}</div>
                        <div style="left: 83.5%; width: 1%;" class="name">${v.distance}</div>
                        <div data-race="${encodeURIComponent(JSON.stringify(v.raceResult))}" class="view-button view-completed">View</div>
                    </div>
                `);
            } else if (v.completed == false) {
                $('.pending-list').append(`
                    <div class="item" data-identifier="${v.identifier}" data-password="${v.password}" data-id="${v.id}" data-players="${encodeURIComponent(JSON.stringify(v.players))}"  data-event-name="${v.eventName}"  data-vehicle-class="${v.vehicleClass}"  data-type="${v.type}"  data-buy-in="${v.buyIn}"  data-laps="${v.laps}"  data-distance="${v.distance}">
                        <div class="name">${v.eventName}</div>
                        <div style="left: 42%; width: 1%;" class="name">Ground Zero</div>
                        <div style="left: 55.5%; width: 1%;" class="name">${v.vehicleClass}</div>
                        <div style="left: 62.5%; width: 1%;" class="name">${v.type}</div>
                        <div style="left: 69.5%; width: 1%;" class="name">$${v.buyIn}</div>
                        <div style="left: 77%; width: 1%;" class="name">${v.laps}</div>
                        <div style="left: 83.5%; width: 1%;" class="name">${v.distance}</div>
                        <div data-laps="${v.laps}" class="view-button view-race">View</div>
                    </div>
                `);
            }

        }
    });

    if ($('.active-list .item').length === 0) {
        $('.no-active').css('display', 'flex');
    } else {
        $('.no-active').hide();
    }

    if ($('.pending-list .item').length === 0) {
        $('.no-pending').css('display', 'flex');
    } else {
        $('.no-pending').hide();
    }
}

function formatDate(timestamp) {
    const date = new Date(timestamp * 1000);
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const year = date.getFullYear();
    return `${month}/${day}/${year}`;
}


function update(data) {
    $('.active-list, .pending-list').empty();
    $.each(data['races'], function (i, v) {
        $.each(v.players, function (x, y) {
            $('.view-user-list').append(`
                <div class="item">
                    <div class="name">${y.alias} </div>
                </div>
            `);
        });

        if (v.startControl) {
            $('.active-list').append(`
                <div class="item">
                  <div class="name">${v.eventName}</div>
                  <div style="left: 42%;width: 1%;" class="name">Ground Zero</div>
                  <div style="left: 55.5%;width: 1%;" class="name">${v.vehicleClass}</div>
                  <div style="left: 62.5%;width: 1%;" class="name">${v.type}</div>
                  <div style="left: 69.5%;width: 1%;" class="name">$${v.buyIn}</div>
                  <div style="left: 77%;width: 1%;" class="name">${v.laps}</div>
                  <div style="left: 83.5%;width: 1%;" class="name">${v.distance}</div>
                  <div class="view-button">View</div>
                </div>
            `);
        } else {
            $('.pending-list').append(`
            <div class="item" data-identifier="${v.identifier}" data-password="${v.password}" data-id="${v.id}" data-players="${encodeURIComponent(JSON.stringify(v.players))}"  data-event-name="${v.eventName}"  data-vehicle-class="${v.vehicleClass}"  data-type="${v.type}"  data-buy-in="${v.buyIn}"  data-laps="${v.laps}"  data-distance="${v.distance}">
                <div class="name">${v.eventName}</div>
                <div style="left: 42%; width: 1%;" class="name">Ground Zero</div>
                <div style="left: 55.5%; width: 1%;" class="name">${v.vehicleClass}</div>
                <div style="left: 62.5%; width: 1%;" class="name">${v.type}</div>
                <div style="left: 69.5%; width: 1%;" class="name">$${v.buyIn}</div>
                <div style="left: 77%; width: 1%;" class="name">${v.laps}</div>
                <div style="left: 83.5%; width: 1%;" class="name">${v.distance}</div>
                <div data-laps="${v.laps}" class="view-button view-race">View</div>
            </div>
            `);
        }
    })


    if ($('.active-list .item').length === 0) {
        $('.no-active').css('display', 'flex');
    } else {
        $('.no-active').hide();
    }

    if ($('.pending-list .item').length === 0) {
        $('.no-pending').css('display', 'flex');
    } else {
        $('.no-pending').hide();
    }
}

$(document).on('click', '.view-completed', function () {
    $('.view-page').hide();
    $('.race-page , .cls-btn').show();
    var metadataObj = JSON.parse(decodeURIComponent($(this).data('race')));

    $('.race-list').empty();

    $.each(metadataObj, function (i, v) {
        var maxRating = 1500;
        var maxCash = 50000;
        var minCash = 1000;

        var cashRange = maxCash - minCash;
        var ratingRange = maxRating;

        var cashFactor = (v.cash - minCash) / cashRange;
        var randomFactor = Math.random();

        var rating = Math.floor((1 - cashFactor) * randomFactor * ratingRange);

        var boxColor = i === 0 ? '#eecd3c' : i === 1 ? 'white' : i === 2 ? '#ff5e35' : '#ffffff';


        $('.race-list').append(`
            <div class="item">
                <div style="background-color: ${boxColor};" class="box"></div>
                <div class="name">#${i + 1}</div>
                <div class="name" style="left: 15%;">${v.alias}</div>
                <div class="name" style="left: 30.5%;color: #28d2a8;">$${v.cash}</div>
                <div class="name" style="left: 40.5%;">1500/ <span style="color: #28d2a8;">${rating}</span> </div>
                <div class="name" style="left: 55.5%;">${formatTimeWithoutMilliseconds(v.finishTime)}</div>
                <div class="name" style="left: 95%;">${formatTimeWithoutMilliseconds(v.bestLapTime)}</div>
            </div>    
        `);
    });
});

$(document).on('click', '.cancel-race-track', function () {
    popup('Are you sure you want to CANCEL this Track?', 'confirm').then((result) => {
        if (result) {
            $.post("http://exter-racingapp/cancelTrack", JSON.stringify({ id: raceId }));
            raceCreated = false;
            $('body').fadeOut(500);
        }
    });
})

$(document).on('click', '.finish-race-track', function () {
    popup('Are you sure you want to FINALIZE this Track?', 'confirm').then((result) => {
        if (result) {
            $.post("http://exter-racingapp/finishTrack", JSON.stringify({ id: raceId }));
            raceCreated = true;
            $('body').fadeOut(500);
        }
    });
})

$(document).on('click', '.create-race-button', function () {
    trackName = $('.trackname').val();

    if (trackName == '' || trackName == null) {
        notification('Please enter a name', 'error');
        return;
    }

    popup("Track values are FINAL, are you sure you want to start Track creation?", "confirm").then((result) => {
        if (result) {

            raceType = $('.racetype-zort').val();
            lap = $('.lap-value').val();

            $.post("http://exter-racingapp/createTrack", JSON.stringify({
                name: trackName,
                type: raceType,
                laps: lap
            }), function (data) {
                notification(data.message, data.type);
                if (data.type == "success") {
                    $('body').fadeOut(500);
                }
            });

            setTimeout(() => {
                $('.create-track-page').hide();
                $('.tracks-page').show();
            }, 1000);
        }
    });
})


$(document).on('click', '.start-race', function () {

    popup("Are you sure you want to start race?", "confirm").then((result) => {
        if (result) {
            $.post("http://exter-racingapp/startrace", JSON.stringify({ id: raceId }), function (data) {
                notification(data.message, data.type);
                if (data.type == "success") {
                    $('body').fadeOut(500);
                }
            });
        }
    });
})

$(document.body).on('click', '.end-race', function () {

    popup("Are you sure you want to end race ?", "confirm").then((result) => {
        if (result) {
            $.post("http://exter-racingapp/endrace", JSON.stringify({ id: raceId }));
            $('.view-page').hide();
            $('.ladder-page , .cls-btn').show();
        }
    });
})


$(document).on('click', '.race-preview', function () {
    $.post("http://exter-racingapp/racepreview", JSON.stringify({ id: raceId }));
})

$(document).on('click', '.join-race', function () {

    if (racePasword != '') {
        popup("Enter the password to join the race ", "input").then((result) => {
            if (result) {
                passwordInput = $('.login-input').val();
                $.post("http://exter-racingapp/joinrace", JSON.stringify({ id: raceId, password: passwordInput }), function (data) {
                    notification(data.message, data.type);
                    $('.view-user-list').empty();
                    if (data.type == "success") {
                        $.each(data.players, function (i, v) {
                            $('.view-user-list').append(`
                                <div class="item">
                                    <div class="name">${v.alias} </div>
                                </div>
                            `);
                        });
                    }
                });
            }
        });
    } else {
        popup("Are you sure you want to join the race?", "confirm").then((result) => {
            if (result) {
                $.post("http://exter-racingapp/joinrace", JSON.stringify({ id: raceId }));
            }
        });
    }

})

$(document).on('click', '.setgps', function () {
    $.post("http://exter-racingapp/setgps", JSON.stringify({ id: raceId }));
    notification('GPS set successfully', 'success');
})

$(document).on('click', '.view-race', function () {
    var raceItem = $(this).closest('.item');
    var eventName = raceItem.data('event-name');
    var vehicleClass = raceItem.data('vehicle-class');
    var type = raceItem.data('type');
    var buyIn = raceItem.data('buy-in');
    var laps = raceItem.data('laps');
    var distance = raceItem.data('distance');
    var players = JSON.parse(decodeURIComponent(raceItem.data('players')));
    var identifier = raceItem.data('identifier');

    if (identifier == currentIdentifier) {
        $('.admin-button').show();
        $('.join-race').hide();
    } else {
        $('.admin-button').hide();
        $('.join-race').show();
    }

    raceId = raceItem.data('id');
    racePasword = raceItem.data('password');
    $('.cls-btn').hide();
    $('#track').text(eventName);
    $("#type").text(type);
    $("#buy-in").text("$" + buyIn);
    $("#laps").text(laps);
    $("#distance").text(distance);
    $("#vehicle-class").text(vehicleClass);

    $('.view-user-list').empty();

    $.each(players, function (i, v) {
        $('.view-user-list').append(`
            <div class="item">
                <div class="name">${v.alias} </div>
            </div>
        `);
    });


    $('.ladder-page').hide();
    $('.view-page').show();
})

// $(document).on('click', '#tracks-item', function() {
//     currentTrackId = $(this).data('id');
//     $('.tracks-page').hide();
//     $('.create-page').show();
// })

$(document).on('click', '.view-button', function () {
    page = $(this).data('page');

    if (page == 'create-track-page') {
        if (raceCreated) {
            $('.cancel-race-track , .finish-race-track').css('display', 'flex');
            $('.create-race-button').hide();
        }
    }

    if (page == 'create-page') {
        currentTrackId = $(this).data('id');
    }

    $('.tracks-page , .create-page , .login-page , .ladder-page , .create-track-page').hide();
    $('.' + page).show();
})

$(document).on('click', '.create-button', function () {
    let inputs = $('.input');
    let missingInputs = [];
    let formData = {};
    let id = $('.tracks-list').find('.item').attr('data-id');

    inputs.each(function () {
        let input = $(this);
        if (input.val().trim() === '') {
            missingInputs.push(input.attr('placeholder'));
            let item = input.closest('.item');
            item.css('background-color', 'rgb(98 49 49)');
            item.find('.right-button').css('background-color', 'rgb(98 49 49)');
            item.find('.left-button').css('background-color', 'rgb(98 49 49)');
        } else {
            let key = input.attr('class').split(' ').filter(function (className) {
                return className !== 'input' && className !== 'custom';
            })[0].replace('-input', '');
            formData[key] = input.val().trim();
            let item = input.closest('.item');
            item.css('background-color', '');
            item.find('.right-button').css('background-color', '');
            item.find('.left-button').css('background-color', '');
        }
    });

    if (missingInputs.length > 0) {
        notification('Please fill in the missing fields', 'error');
        setTimeout(() => {
            inputs.each(function () {
                if ($(this).val().trim() === '') {
                    let item = $(this).closest('.item');
                    item.css('background-color', '');
                    item.find('.right-button').css('background-color', '');
                    item.find('.left-button').css('background-color', '');
                }
            });
        }, 3000);
    } else {
        formData['id'] = id;
        formData['currentTrackId'] = currentTrackId;
        $.post("http://exter-racingapp/createRace", JSON.stringify(formData), function (data) {
            notification(data.message, data.type);
            setTimeout(() => {
                $('.create-page').hide();
                $('.ladder-page').show();
            }, 500);
        });
    }
});


$(document).on('click', '.close', function () {
    $('.app-big').fadeOut(500);
})

$(document).on('click', '.setup', function () {
    $('.login-page').hide();
    $('.loading-page').show();

    setTimeout(() => {
        $('.loading-page').hide();
        $('.ladder-page , .cls-btn').show();
    }, 1000);

    val = $('.alias-name').val();

    if (val == '' || val == null) {
        notification('Please enter a name', 'error');
        return;
    }

    $.post("http://exter-racingapp/login", JSON.stringify({ alias: val }), function (data) {
        notification(data.message, data.type);
        if (data.type == "success") {
            alias = data.alias;
        }
    });
})

$(document).on('click', '.app', function () {
    $('.loading-page').show();

    setTimeout(() => {
        $('.loading-page').hide();
    }, 2000);
    $('.app-big').fadeIn(500);
    $('.app-big').css('display', 'flex');

    if (alias == '' || alias == null) {
        $('.login-page').show();
        $('.tracks-page , .create-page  , .view-page  , .ladder-page , .cls-btn').hide();
    } else {
        $('.ladder-page , .cls-btn').show();
    }

})

$(document).on('click', '.box-left #races', function () {
    $('.ladder-page , .cls-btn').show();
    $('.tracks-page , .create-track-page, .create-page , .login-page , .view-page , .loading-page , .racer-ladder').hide();
})


function notification(text, type) {
    const notificationElement = $('.notification');
    const iconSpan = notificationElement.find('span');

    notificationElement.css({
        top: '-10%',
        opacity: 0,
    });

    notificationElement.find('.text').text(text);

    if (type === 'success') {
        iconSpan.text('✓');
        iconSpan.css('background-color', '#28a745');
    } else if (type === 'error') {
        iconSpan.text('!');
        iconSpan.css('background-color', '#f6655a');
    }

    notificationElement.show();

    notificationElement.animate({
        top: '7%',
        opacity: 1
    }, 500);

    setTimeout(() => {
        notificationElement.animate({
            top: '-10%',
            opacity: 0
        }, 500, () => {
            notificationElement.hide();
        });
    }, 3000);
}

function popup(text, type) {
    return new Promise((resolve, reject) => {
        $('.popup').text(text).fadeIn(500);
        $('.pop-up').css('display', 'flex');
        $('.pop-alt').text(text);
        if (type == 'input') {
            $('.login-input').css('display', 'flex');
            $('.pop-alt').css('display', 'none');
        } else {
            $('.login-input').css('display', 'none');
            $('.pop-alt').css('display', 'flex');
        }

        $('.pop-up').fadeIn(500);

        $('.pop-yes').off('click').on('click', function () {
            $('.pop-up').fadeOut(500);
            resolve(true);
        });

        $('.pop-no').off('click').on('click', function () {
            $('.pop-up').fadeOut(500);
            resolve(false);
        });
    });
}

let vehicleClasses = ["Open", "Slow", "Fast"];
$(document).on('click', '.vehicleclass-right', function () {
    let currentClass = $('.vehicleclass-input').val();
    let currentIndex = vehicleClasses.indexOf(currentClass);
    let nextIndex = (currentIndex + 1) % vehicleClasses.length;
    $('.vehicleclass-input').val(vehicleClasses[nextIndex]);
})

$(document).on('click', '.vehicleclass-left', function () {
    let currentClass = $('.vehicleclass-input').val();
    let currentIndex = vehicleClasses.indexOf(currentClass);
    let prevIndex = (currentIndex - 1 + vehicleClasses.length) % vehicleClasses.length;
    $('.vehicleclass-input').val(vehicleClasses[prevIndex]);
})

$(document).on('click', '.notification-right, .notification-left', function () {
    toggleYesNo($('.notification-input'));
})

$(document).on('click', '.reverse-right, .reverse-left', function () {
    toggleYesNo($('.reverse-input'));
})

$(document).on('click', '.showposition-right, .showposition-left', function () {
    toggleYesNo($('.showposition-input'));
})

$(document).on('click', '.forcefpp-right, .forcefpp-left', function () {
    toggleYesNo($('.forcefpp-input'));
})


$(document).on('click', '.racetype-right, .racetype-left', function () {
    toggleSprintLab($('.racetype-zort'));
})

function toggleSprintLab(inputElement) {
    if (inputElement.val() === "Sprint") {
        inputElement.val("Lap");
        $('.lapsdiv').show();
    } else {
        $('.lapsdiv').hide();
        inputElement.val("Sprint");
    }
}



function toggleYesNo(inputElement) {
    if (inputElement.val() === "Yes") {
        inputElement.val("No");
    } else {
        inputElement.val("Yes");
    }
}


$(document).keyup(function (e) {
    if (e.keyCode === 27) {
        $("body").fadeOut(500);
        $.post("http://exter-racingapp/close", JSON.stringify({}));
    }
});



function updateTime() {
    const timeElement = document.querySelector('.time');
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const year = now.getFullYear();

    timeElement.textContent = `${hours}:${minutes}:${seconds} ${month}/${day}/${year}`;
}

setInterval(updateTime, 1000);
updateTime();

