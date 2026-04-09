<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::get('/test', function () {
    return 'Hello from Laravel';
});

Route::post('/names', function (Request $request) {
    $name = $request->name;

    $success = DB::insert('
        insert into persons (name)
        values (?);
    ', [$name]);

    return $success;
});

Route::get('/names', function () {
    $names = DB::select('
        select name from persons;
    ');

    return $names;
});
