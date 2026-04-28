from agent import search_parties

def debug_search():
    print("Testing search_parties('Japan')...")
    results = search_parties.invoke("Japan")
    print(f"Results found: {len(results)}")
    for r in results:
        print(f" - {r['title']} ({r['country']})")

if __name__ == "__main__":
    debug_search()
