{Connection} = require '../../connection'
{AND, OR, NOT, SELECT, INSERT, UPDATE, DELETE} = require '../../constants'
{BASE_FIELDS} = require './fields'

try
    pg = require 'pg'
catch err
    try
        pg = require 'pg/lib'
    catch err
        throw new Error '``pg`` must be installed to use the postgres backend.'

PGWrapper = (client)->
    @client = client
    @

PGWrapper::execute = (sql, values, mode, model, ready)->
    if mode is INSERT
        sql += ' RETURNING *'
    @client.query sql, values, (err, data)->
        if mode in [SELECT, INSERT]
            ready err, if not err then data.rows else null
        else
            ready err, data

PGWrapper::close = (ready)->
    @client.end()
    if ready instanceof Function then ready()

PGConnection = (metadata)->
    @metadata = metadata
    @

PGConnection:: = new Connection

PGConnection::constraint = (constraint)->
    constraint

PGConnection::quote = (what)->
    "\"#{what.replace /\"/g, '\"\"'}\""

PGConnection::negotiate_type = (field, force_type)->
    BASE_FIELDS[force_type or field.db_type](field, @)

PGConnection::close = (ready)->
    @client (client)->
        client.close ready

PGConnection::get_client =(ready)->
    config =
        user: @metadata.user
        password: @metadata.password
        database: @metadata.name
        host: @metadata.host or 'localhost'
        port: @metadata.port or 5432

    pg.connect config, (err, client)->
        if err then throw err
        ready new PGWrapper client

exports.Connection = PGConnection