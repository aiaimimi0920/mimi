from colorama import Fore

ANSWER_POST_SCRIPT =  """
    return fetch("https://mubert.com/v1/TrackCreate", {
    "headers": {
        "content-type": "application/json",
    },
    "referrerPolicy": "strict-origin-when-cross-origin",
    "body": arguments[0],
    "method": "POST",
    "mode": "cors",
    "credentials": "include"
    }).then(res => res.text());
    """


ASYNC_ANSWER_POST_SCRIPT =  """
    var callback = arguments[arguments.length - 1];
    return fetch("https://mubert.com/v1/TrackCreate", {
    "headers": {
        "content-type": "application/json",
    },
    "referrerPolicy": "strict-origin-when-cross-origin",
    "body": arguments[0],
    "method": "POST",
    "mode": "cors",
    "credentials": "include"
    }).then(res => res.text()).then(res => callback(res));
    """
BASE_URL = 'https://mubert.com/render'
MUSIC_URL = 'https://static-eu.gcp.mubert.com/backend_content/render/prod/tracks/mp3/{}.mp3'