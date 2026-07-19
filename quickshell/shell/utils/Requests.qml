pragma Singleton

import QtQuick

// Thin XMLHttpRequest GET helper — parses JSON responses before handing
// them to the callback.
QtObject {
    id: root

    function get(url: string, onSuccess: var, onError: var): void {
        const xhr = new XMLHttpRequest();

        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            if (xhr.status < 200 || xhr.status >= 300) {
                console.warn("Requests.get: HTTP", xhr.status, "for", url);
                if (onError)
                    onError(xhr.status);
                return;
            }

            try {
                const data = JSON.parse(xhr.responseText);
                if (onSuccess)
                    onSuccess(data);
            } catch (e) {
                console.warn("Requests.get: failed to parse JSON from", url, e);
                if (onError)
                    onError(e);
            }
        };

        xhr.open("GET", url);
        xhr.send();
    }
}
