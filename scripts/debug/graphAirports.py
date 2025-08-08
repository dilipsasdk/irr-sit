from mpl_toolkits.basemap import Basemap as Basemap
from tkinter.filedialog import askopenfilename
import matplotlib.patches as mpatches
import matplotlib.pyplot as plt
import networkx as nx
import pandas as pd
import json
import os

PATH = os.path.dirname(os.path.abspath(__file__))
AIRPORT_PATH = PATH + "/../create-org-mock-data/Airport__c.csv"

def main():
    trips = parseDebug()
    airports = loadAirports()
    for index, t in enumerate(trips):
        print(f'Making graph for trip {index+1} out of {len(trips)}')
        makeGraph(t, airports, f'Trip no {index+1}')
        # visualizeSegments(t)
    
    if len(trips) == 0:
        print('No debugged trips in the debug log.')

def visualizeSegments(t):
    legs = t.get('sortedLegs')
    for index,leg in enumerate(legs):
        print(f'Leg no {index+1}')
        print('Segment types should be: ' + leg.get('segmentType'))
        for s in leg.get('segments'):
            print(s.get('Trip_Type__c'))
            flight = s.get('Flight__r')
            print(flight.get('Departure_Airport__c'))
            print(flight.get('Arrival_Airport__c'))

def loadAirports():
    df = pd.read_csv(AIRPORT_PATH).set_index('TEDS_Identifier__c')
    return df

def parseDebug():
    print('Choose a debug log')
    debugLog = askopenfilename()
    jsonTrips = []
    parsedTrips = []
    print('Going through the debug log...')
    with open(debugLog) as file:
        saveLine = False
        while True:
            line = file.readline()
            if not line:
                break
            if saveLine:
                jsonTrips.append(line)
                saveLine = False
            if 'TRIP-DEBUG' in line:
                if 'START' in line:
                    saveLine = True

    print('Parsing json-data...')
    for jsonTrip in jsonTrips:
        data = json.loads(jsonTrip)
        parsedTrips.append(data)
    return parsedTrips

def makeGraph(data, airports, name):
    sortedLegs = data.get('sortedLegs')
    G = mapAirports(sortedLegs)
    pos = drawEarth(G, airports)
    nx.draw(G, pos,with_labels=True, node_color=getNodeColors(G, data.get('originAirport'), data.get('destinationAirport')), node_size=1250, font_size=14)
    ax = plt.gca()
    ax.margins(0.1) 
    G, edgeColors = addEdges(G, sortedLegs)
    addFlightRoutes(G, edgeColors, pos, ax)
    plt.savefig(name, bbox_inches="tight")
    plt.close()

def drawEarth(G, airports):
    pos = {}
    longMin, latMin, longMax, latMax = 500, 500, -500, -500
    for code in G.nodes:
        long = airports.loc[code]['Longitude__c']
        lat = airports.loc[code]['Latitude__c']
        pos[code] = (long, lat)
        if long < longMin:
            longMin = long
        if long > longMax:
            longMax = long
        if lat < latMin:
            latMin = lat
        if lat > latMax:
            latMax = lat

    plt.figure(figsize = (12,12))
    m = Basemap(projection='cyl', llcrnrlon=longMin-5, llcrnrlat=latMin-5, urcrnrlon=longMax+5, urcrnrlat=latMax+5, resolution='l')
    m.drawcountries(linewidth=0.5)
    m.drawmapboundary(fill_color='lightblue')
    m.fillcontinents(color='gainsboro',lake_color='lightblue')
    m.drawcoastlines(linewidth=0.5)

    return pos

def addFlightRoutes(G, edgeColors, pos, ax):
    for index, e in enumerate(G.edges):
        col = edgeColors[index]
        diff = 0.1
        position = 0.1*e[2] + diff
        ax.annotate("",
                    xy=pos[e[0]], xycoords='data',
                    xytext=pos[e[1]], textcoords='data',
                    arrowprops=dict(arrowstyle="<|-", mutation_scale=25, color=col,lw=2,
                                    shrinkA=17, shrinkB=17,
                                    connectionstyle="arc3,rad=rrr".replace('rrr',str(position))))
    
    origin_patch = mpatches.Patch(color='limegreen', label='Origin')
    transition_patch = mpatches.Patch(color='silver', label='Transit')
    destination_patch = mpatches.Patch(color='dodgerblue', label='Destination')
    plt.legend(handles=[origin_patch, transition_patch, destination_patch])

def mapAirports(sortedLegs):
    plt.clf()
    plt.cla()
    G=nx.MultiDiGraph()
    addedAirports = []
    for leg in sortedLegs:
        departureAirport = leg.get('flight').get("Departure_Airport__c")
        arrivalAirport = leg.get('flight').get("Arrival_Airport__c")
        if (departureAirport not in addedAirports):
            G.add_node(departureAirport)
            addedAirports.append(departureAirport)
        if (arrivalAirport not in addedAirports):
            G.add_node(arrivalAirport)
            addedAirports.append(arrivalAirport)
    return G

def getNodeColors(G, origin, destination):
    nodeColors = []
    for node in G.nodes:
        if node == origin.get('TEDS_Identifier__c'):
            nodeColors.append('limegreen')
        elif node == destination.get('TEDS_Identifier__c'):
            nodeColors.append('dodgerblue')
        else:
            nodeColors.append('silver')

    return nodeColors

def addEdges(G, sortedLegs):
    edgeColors = []
    for leg in sortedLegs:
        departureAirport = leg.get('flight').get("Departure_Airport__c")
        arrivalAirport = leg.get('flight').get("Arrival_Airport__c")

        G.add_edge(departureAirport, arrivalAirport)
        segmentColour = 'gold' # Unknown
        if leg.get("segmentType") == 'Cancelled':
            segmentColour = 'red'
        elif leg.get("segmentType") in ['Outbound', 'Inbound']:
            segmentColour = 'black'
        edgeColors.append(segmentColour)
    
    return G, edgeColors

if __name__ == "__main__":
    main()