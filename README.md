# Benchy

I wrote this one day because I was trying to test upload performance and no tools out there were cutting it. You can do sane stuff like:

    benchy post http://127.0.0.1:8080/ -c 10 < my_pic.jpg # Simulates 10 concurrent HTTP POST requests

or

    benchy get http://127.0.0.1:8080/ # Just run a GET request

and it runs indefintely until you kill the process.
