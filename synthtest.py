import json
import logging
import os
import uuid

from hec import HEC

logging.basicConfig(
    format='%(asctime)s %(levelname)-8s %(message)s',
    level=logging.INFO,
    datefmt='%Y-%m-%d %H:%M:%S')

def runtests():
    stats = {'rules': 0, 'events': 0}

    for test in next(os.walk('./tests/.'))[1]:

        with open(f'tests/{test}/events.json', 'r') as file:
            events = json.load(file)

        with open(f'tests/{test}/config.json', 'r') as file:
            config = json.load(file)

        test_id = str(uuid.uuid4())
        metadata = {"index": config['index'], "host":f"test_{test_id}", "sourcetype": config["sourcetype"]}
        stats['rules'] += 1

        for event in events:
            try:
                hec.send(event, metadata)
            except:
                logging.error('Failed to send to HEC endpoint!')
                return

            stats['events'] += 1

        test_run = {
                'test_id': test_id,
                'tests_rule': config['tests_rule'],
                'expected_within': config['expected_within']
        }
        try:
            hec.send(
                test_run,
                {
                    "index": "synthtest",
                    "sourcetype": "test_run"
                }
            )
        except:
            logging.error('Failed to send to HEC endpoint!')
            return

    logging.info(f'Complete. Sent {stats['events']} events for {stats['rules']} rules.')

if __name__ == '__main__':
    hec = HEC(os.environ["HEC_TOKEN"], "https://127.0.0.1")
    logging.info('Starting test run.')
    runtests()
