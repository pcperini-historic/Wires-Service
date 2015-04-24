'use strict';

/**
 * Safely access the response body.
 *
 * @param {XHR} xhr XHR request who's body we need to safely extract.
 * @returns {Mixed} The response body.
 * @api public
 */
module.exports = function get(xhr) {
  if (xhr.response) return xhr.response;

  //
  // Browser bugs:
  //
  // IE<10:   Accessing binary data's responseText will throw an Exception
  // Chrome:  When responseType is set to Blob it will throw errors even when
  //          Accessing the responseText property.
  //
  if ('blob' !== xhr.responseType && 'string' === typeof xhr.responseText) {
    return xhr.responseText || xhr.responseXML;
  }
};
