// **********************************************************************
//
// Copyright (c) 2001
// MutableRealms, Inc.
// Huntsville, AL, USA
//
// All Rights Reserved
//
// **********************************************************************

#ifndef FREEZE_DB_ICE
#define FREEZE_DB_ICE

#include <Ice/CommunicatorF.ice>
#include <Freeze/DBException.ice>
#include <Freeze/DBF.ice>
#include <Freeze/EvictorF.ice>

/**
 *
 * The Ice module for object persistence.
 *
 **/
module Freeze
{

/**
 *
 * A database environment. Multiple databases can be created from a
 * single database environment. The database environment also offers
 * operations to create transactions.
 *
 * @see DBTransaction
 * @see DB
 *
 **/
local interface DBEnvironment
{
    /**
     *
     * Get the name of the database environment.
     *
     * @return The name of this database environment.
     *
     **/
    string getName();
     
    /**
     *
     * Get the Communicator for this database environment.
     *
     * @return The Communicator for this database environment.
     *
     **/
    Ice::Communicator getCommunicator();
     
    /**
     *
     * Open and return a database object. If the database has been
     * opened before, the previously returned database object is
     * returned again.
     *
     * @param name The database name.
     *
     * @return The database object.
     *
     * @throws DBException Raised if a database failure occurred.
     *
     * @see DB
     * @see DB::close
     *
     **/
    DB openDB(string name) throws DBException;

    /**
     *
     * Start a new transaction in this database environment, and
     * return the transaction object for such new transaction.
     *
     * @return The transaction object.
     *
     * @throws DBException Raised if a database failure occurred.
     *
     * @see DBTransaction
     *
     **/
    DBTransaction startTransaction() throws DBException;

    /**
     *
     * Close the database environment and destroy this database
     * environment object. This operation also calls [close] on all
     * databases that have been opened with this database environment
     * object. Subsequent calls to [close] have no effect.
     *
     * @throws DBException Raised if a database failure occurred.
     *
     * @see DB::close
     *
     **/
    void close() throws DBException;
};

/**
 *
 * A transaction object.
 *
 * @see DBEnvironment
 *
 **/
local interface DBTransaction
{
    /**
     *
     * Commit a transaction.
     *
     * @throws DBException Raised if a database failure occurred.
     *
     **/
    void commit() throws DBException;

    /**
     *
     * Abort a transaction.
     *
     * @throws DBException Raised if a database failure occurred.
     *
     **/
    void abort() throws DBException;
};

/**
 *
 * The Evictor persistence mode.
 *
 * @see Evictor
 *
 **/
enum EvictorPersistenceMode
{
    /**
     *
     * This mode instructs the Evictor to save a Servant to persistent
     * store when it is evicted, or when the Evictor is deactivated.
     *
     * @see Ice::ServantLocator::deactivate
     *
     **/
    SaveUponEviction,

    /**
     *
     * This mode instructs the Evictor to save a Servant after each
     * mutating operation call. A mutating operation call is a call to
     * any operation that has not been declared as [nonmutating].
     *
     **/
    SaveAfterMutatingOperation
};

/**
 *
 * A database key, represented as a sequence of bytes.
 *
 **/
sequence<byte> Key;

/**
 *
 * A database value, represented as a sequence of bytes
 *
 **/
sequence<byte> Value;

/**
 *
 * A database cursor provides a way to iterate through all key/value
 * pairs in the database.
 *
 * @see DB
 * @see DB::getCursor
 * @see DB::getCursorForKey
 *
 **/
local interface DBCursor
{
    /**
     *
     * Get the Communicator for this cursor.
     *
     * @return The Communicator for this database.
     *
     **/
    Ice::Communicator getCommunicator();

    /**
     *
     * Determine if there are more elements in the database.
     *
     * @return Returns true if the cursor has more elements, false
     * otherwise.
     *
     * @throws DBDeadlockException Raised if a deadlock occurred.
     *
     * @throws DBException Raised if any other database failure
     * occurred.
     *
     **/
    bool hasNext() throws DBException;

    /**
     *
     * Return the next element in the database.
     *
     * @param key The key of the next element.
     * @param value The value of the next element
     *
     * @throws DBNotFoundException If there are no further elements in
     * the database.
     *
     * @throws DBDeadlockException Raised if a deadlock occurred.
     *
     * @throws DBException Raised if any other database failure
     * occurred.
     *
     **/
    void next(; Key key, Value value) throws DBException;

    /**
     *
     * Remove the last element returned by the cursor. This method can
     * only be called once per call to [next].
     *
     * @throws DBNotFoundException If the next method has not yet been
     * called, or the [remove] method has already been called after the
     * last call to the [next] method.
     *
     * @throws DBDeadlockException Raised if a deadlock occurred.
     *
     * @throws DBException Raised if any other database failure
     * occurred.
     *
     **/
    void remove() throws DBException;

    /**
     *
     * Clone the cursor.
     *
     * @return The cloned cursor.
     *
     * @throws DBException Raised if the cursor has been closed.
     *
     **/
    DBCursor clone() throws DBException;

    /**
     *
     * Close the cursor. Subsequent calls to [close] have no effect.
     *
     **/
    void close();
};

/**
 *
 * A database that can store basic key/value pairs, or
 * identity/servant pairs. In case the database is used to store both
 * key/value and identity/Servant pairs, it is the application's
 * responsbility to make sure that there is no overlap between keys
 * and identities. Identities are simply strings, while values are
 * sequence of bytes. This means that no byte representation of
 * identity strings may be equal to any of the keys. Due to the
 * difficulty to avoid this in practice, the use of one single
 * database to store both key/value and identity/Servant pairs is
 * discouraged.
 *
 * @see DBEnvironment
 * @see DBCursor
 * @see Evictor
 *
 **/
local interface DB
{
    /**
     *
     * Get the Communicator for this database.
     *
     * @return The Communicator for this database.
     *
     **/
    Ice::Communicator getCommunicator();

    /**
     *
     * Get the name of the database.
     *
     * @return The name of this database.
     *
     **/
    string getName();

    /**
     *
     * Get number of key/value pairs in the database.
     *
     * @return The number of pairs.
     *
     * @throws DBException Raised if the database has been closed.
     *
     **/
    long getNumberRecords() throws DBException;

    /**
     *
     * Create a cursor for this database.
     *
     * @return A database cursor.
     *
     * @throws DBException Raised if the database has been closed.
     *
     * @see DBCursor
     * @see getCursorForKey
     *
     **/
    DBCursor getCursor() throws DBException;

    /**
     *
     * Create a cursor for this database. Calling [next] on the cursor
     * will return the key/value pair for the given key.
     *
     * @return A database cursor.
     *
     * @throws DBNotFoundException If the key was not found in the
     * database.
     *
     * @throws DBDeadlockException Raised if a deadlock occurred.
     *
     * @throws DBException Raised if any other database failure
     * occurred.
     *
     * @see DBCursor
     * @see getCursor
     *
     **/
    DBCursor getCursorForKey(Key key) throws DBException;

    /**
     *
     * Save a value in the database under a given key.
     *
     * @param key The key under which the value will be stored in
     * the database.
     *
     * @param servant The value to store.
     *
     * @throws DBDeadlockException Raised if a deadlock occurred.
     *
     * @throws DBException Raised if any other database failure
     * occurred.
     *
     * @see get
     * @see del
     *
     **/
    void put(Key key, Value value) throws DBException;

    /**
     *
     * Get a value from a database by it's key.
     *
     * @param key The key under which the value is stored in the database
     *
     * @return The value from the database.
     *
     * @throws DBNotFoundException Raised if the key was not found in
     * the database.
     *
     * @throws DBDeadlockException Raised if a deadlock occurred.
     *
     * @throws DBException Raised if any other database failure
     * occurred.
     *
     * @see put
     * @see del
     *
     **/
    Value get(Key key) throws DBException;

    /**
     *
     * Remove a key and the corresponding value from the database. If
     * the key does not exist, this operation will do nothing.
     *
     * @param key The key to remove together with the corresponding
     * value.
     *
     * @throws DBNotFoundException Raised if the key was not found in
     * the database.
     *
     * @throws DBDeadlockException Raised if a deadlock occurred.
     *
     * @throws DBException Raised if any other database failure
     * occurred.
     *
     * @see put
     * @see get
     *
     **/
    void del(Key key) throws DBException;

    /**
     *
     * Put a Servant into the database, using the Ice Object's
     * identity implemented by the Servant as a key.
     *
     * @param identity The identity under which the servant will be
     * stored in the database.
     *
     * @param servant The servant to store. If the servant is null,
     * this operation does nothing.
     *
     * @throws DBDeadlockException Raised if a deadlock occurred.
     *
     * @throws DBException Raised if any other database failure
     * occurred.
     *
     * @see getServant
     * @see delServant
     *
     **/
    void putServant(string identity, Object servant) throws DBException;

    /**
     *
     * Get a Servant from the database by the Ice Object's identity
     * which the Servant must implement.
     *
     * @param identity The identity under which the servant is stored
     * in the database.
     *
     * @return The Servant from the database, or null if the identity
     * does not exist.
     *
     * @throws DBNotFoundException Raised if the Servant's identity
     * was not found in the database.
     *
     * @throws DBDeadlockException Raised if a deadlock occurred.
     *
     * @throws DBException Raised if any other database failure
     * occurred.
     *
     * @see putServant
     * @see delServant
     *
     **/
    Object getServant(string identity) throws DBException;

    /**
     *
     * Remove an identity and the corresponding Servant from the
     * database. If the identity does not exist, this operation will
     * do nothing.
     *
     * @param identity The identity to remove together with the
     * corresponding Servant.
     *
     * @throws DBNotFoundException Raised if the Servant's identity
     * was not found in the database.
     *
     * @throws DBDeadlockException Raised if a deadlock occurred.
     *
     * @throws DBException Raised if any other database failure
     * occurred.
     *
     * @see putServant
     * @see getServant
     *
     **/
    void delServant(string identity) throws DBException;

    /**
     *
     * Clear the database of all records.
     *
     * @throws DBException Raised if a database failure occurred.
     * 
     **/
    void clear() throws DBException;

    /**
     *
     * Close the database and destroy this database object. Subsequent
     * calls to [close] have no effect.
     *
     * @throws DBException Raised if a database failure occurred.
     *
     * @see DBEnvironment::openDB
     * @see DBEnvironment::close
     *
     **/
    void close() throws DBException;

    /**
     *
     * Create a new Evictor that uses this database to store
     * identity/Servant pairs.
     *
     * <note><para>Care must be taken to not to close this database,
     * or the database environment this database belongs to, before
     * the Evictor has been properly deactivated. The Evictor is
     * deactivated by calling [Ice::ObjectAdapter::deactivate] on the
     * Object Adapter this Evictor is installed with, or by shutting
     * down all Object Adapters with [Ice::Communicator::shutdown]
     * followed by [Ice::Communicator::waitForShutdown].</para></note>
     *
     * @param mode The persistence mode for the new Evictor.
     *
     * @return The new Evictor.
     *
     * @see Evictor
     * @see EvictorPersistenceMode
     *
     **/
    Evictor createEvictor(EvictorPersistenceMode mode);
};

};

#endif
