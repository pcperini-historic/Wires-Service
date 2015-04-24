describe('xhr-response', function () {
  'use strict';

  var assume = require('assume')
    , response = require('./');

  it('is exported as a function', function () {
    assume(response).is.a('function');
  });

  it('defaults to the `reponse` property when available', function () {
    var wat = response({
      response: 'wat',
      responseText: 'lol'
    });

    assume(wat).equals('wat');
  });

  it('does not access the `responseText` for `blob` types', function () {
    var wat = response({
      responseText: 'lol',
      responseType: 'blob'
    });

    assume(wat).is.a('undefined');
  });

  it('returns the responseXML if there is no text', function () {
    var wat = response({
      responseText: '',
      responseXML: '<xml>'
    });

    assume(wat).equals('<xml>');
  });
});
