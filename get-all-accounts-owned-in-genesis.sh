#!/usr/bin/env bash

cd "$(dirname "$0")"

RPC_URL="$1"

echo === Foundation Stake Accounts ===
./get-owned-authorized-accounts.sh "$RPC_URL" 4xh7vtQCTim3vgpQ1dQQWjtKrBSkbtL3s15FimXVJAAP --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" 95Nf8XfoecteSXU9nbcvzkrFQdu6FqPaH3EvhwLaC83t --display_summary

echo === Grant Stake Accounts ===
./get-owned-authorized-accounts.sh "$RPC_URL" 8w5cgUQfXAZZWyVgenPHpQ1uABXUVLnymqXbuZPx7yqt --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" 9eyXtP43dCp59oyvWG2R7WQCeJ2bA6TWoLzXg1KTDfQQ --display_summary

echo === Community Stake Accounts ===
./get-owned-authorized-accounts.sh "$RPC_URL" Eo1iDtrZZiAkQFA8u431hedChaSUnPbU8MWg849MFvEZ --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" 7KCzZCbZz6V1U1YXUpBNaqQzQCg2DKo8JsNhKASKtYxe --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" 2J8mJU6tWg78DdQVEqMfpN3rMeNbcRT9qGL3yLbmSXYL --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" 7vEAL3nS9CWmy1q6njUUyHE7Cf5RmyQpND6CsoHjzPiR --display_summary

echo === Service Stake Accounts ===
./get-owned-authorized-accounts.sh "$RPC_URL" B1hegzthtfNQxyEPzkESySxRjMidNqaxrzbQ28GaEwn8 --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" 4AcoZa1P8fF5XK21RJsiuMRZPEScbbWNc75oakRFHiBz --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" AkJ7yssRqS3X4UWLUsPTxbP6LfVgdPYBWH4Jgk5EETgZ --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" 4DVkqvRP8y26JvzNwsnQEQuC7HASwpGs58GsAT9XJMVg --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" B2EWnwgmNd3KMpD71yZMijhML1jd4TYp96zJdhMiWZ7b --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" HtQS1CH3nsUHmnLpenj5W6KHzFWTf3mzCn1mTqK7LkB7 --display_summary

echo === Creator Stake Accounts ===
./get-owned-authorized-accounts.sh "$RPC_URL" uE3TVEffRp69mrgknYr71M18GDqL7GxCNGYYRjb3oUt --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" 9noVEZreMmgQvE8iyKmxy7CGTJ2enELyuJ1qxFtXrfJB --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" BU7LA4kYvicfPCp22EM2Tth3eaeWAXYo6yCgWXQFJ42z --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" BrNFrFeuev8TosKhRe2kvVZTYrcUuYaqCfptWutxs17B --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" 34HCVh8Yx4jNkaeLUQEKibFKUZDPQMjWzkXy8qUfdhS4 --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" AyZb3xrZE8wnS6gYBdsJg5v8CjyrX2ZGXU2zMakCFyYd --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" 7SbpY8LmZUb5XRqDbyoreUrSVVV9c39wkpEz81kEAXu5 --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" C9CfFpmLDsQsz6wt7MrrZquNB5oS4QkpJkmDAiboVEZZ --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" 5WbxKiW7bghkr8JN6ZAv2TQt4PfJFvtuqNaN8gyQ5UzU --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" Gc8XnHU6Nnriwt9RbEwi7PTosx4YanLyXak9GTbB8VaH --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" AMmYEynkd78uNTZDFFrMw6NKjWTgqW7M8EFjvajk23VR --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" 4qWoqt71p7h6siSDS6osu4oVWpw8R7E6uYYiY7Z6oJbH --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" GYitoBY53E9awc56NWHJ2kxMwj4do5GSmvTRowjGaRDw --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" Drg9uSvSEfjtn15jqmmrEQnA4pvU1ToYSGSa1Dv9C6Fk --display_summary
./get-owned-authorized-accounts.sh "$RPC_URL" 95HsPFFvwbWpk42MKzenauSoULNzk8Tg6fc6EiJhLsUZ --display_summary