#!/bin/bash

curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "PHI-DEN", "score": "10-15"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "PHI-DEN", "score": "12-26"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "NYK-GSW", "score": "20-3"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "LAL-BOS", "score": "10-2"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "NYK-GSW", "score": "43-17"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "PHI-DEN", "score": "50-68"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "LAL-BOS", "score": "20-17"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "LAL-BOS", "score": "34-25"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "NYK-GSW", "score": "50-48"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "PHI-DEN", "score": "102-109"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "NYK-GSW", "score": "90-120"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "LAL-BOS", "score": "50-32"}'

# Additional scores
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "NYK-GSW", "score": "108-121"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "LAL-BOS", "score": "64-45"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "PHI-DEN", "score": "115-117"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "NYK-GSW", "score": "122-125"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "LAL-BOS", "score": "82-70"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "PHI-DEN", "score": "120-119"}'
curl -X POST http://localhost:7000/score -H "Content-Type: application/json" -d '{"game_id": "NYK-GSW", "score": "130-128"}'
