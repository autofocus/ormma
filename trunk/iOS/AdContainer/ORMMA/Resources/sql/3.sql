/*
 * Used to store-and-forward off-line requests for URLs.
 */
CREATE TABLE proxy_requests (
   request      TEXT NOT NULL,  -- the URI to call
   submitted_on TEXT NOT NULL   -- when the request was originally requested
);



/*
 * Index based on when resources were submitted.
 */
CREATE INDEX proxy_requests_submitted_idx ON proxy_requests( submitted_on );
