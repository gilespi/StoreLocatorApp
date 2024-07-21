<template>
  <div class="container mx-auto flex flex-col justify-center md:flex-row mt-20">
    <div id="map" class="border shadow-2xl rounded w-full md:w-full mb-4 md:mb-0 mr-0 md:mr-4" style="height: 400px;"></div>
  </div>

  <!-- Notification -->
  <div v-if="showNotification" class="relative inset-0 flex items-center justify-center z-50">
    <div :class="[notificationClass, 'text-white p-4 rounded']">
      {{ notificationMessage }}
    </div>
  </div>

  <!-- Form and Results List -->
  <div class="container mx-auto my-10">


    <div class="flex flex-col md:flex-row">
      <div class="mb-4 mx-3">
        <!-- Store Type Selection -->
        <select v-model="storeType" class="block w-full md:w-96 px-3.5 py-2 mt-4 text-sm font-normal shadow-xs text-gray-900 bg-transparent border border-gray-300 rounded-lg placeholder-gray-400 focus:outline-none leading-relaxed">
          <option disabled value="">Store Type</option>
          <option>Electronics</option>
          <option>Pharmacy</option>
          <option>Restaurant</option>
          <option>Supermarket</option>
        </select>

        <input
            type="text"
            id="small-input"
            v-model="storeName"
            class="block w-full md:w-96 px-3.5 py-2 mt-4 text-sm font-normal shadow-xs text-gray-900 bg-transparent border border-gray-300 rounded-lg placeholder-gray-400 focus:outline-none leading-relaxed"
            placeholder="Store Name"
        />

        <input
            type="text"
            id="autocomplete"
            class="block w-full md:w-96 px-3.5 py-2 mt-4 text-sm font-normal shadow-xs text-gray-900 bg-transparent border border-gray-300 rounded-lg placeholder-gray-400 focus:outline-none leading-relaxed"
            v-model="city"
            placeholder="City"
        />

        <input
            type="text"
            id="autocomplete"
            class="block w-full md:w-96 px-3.5 py-2 mt-4 text-sm font-normal shadow-xs text-gray-900 bg-transparent border border-gray-300 rounded-lg placeholder-gray-400 focus:outline-none leading-relaxed"
            v-model="address"
            placeholder="Address"
        />

        <div class="flex justify-between mt-3">
          <button @click="addStore" class="text-white bg-gradient-to-r from-green-400 via-green-500 to-green-600 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-green-300 dark:focus:ring-green-800 font-medium rounded-lg text-sm px-5 py-1.5 text-center me-2 mb-2">
            {{ editIndex !== null ? 'Update Store' : 'Add Store' }}
          </button>
          <button @click="removeSelectedStores" class="text-white bg-gradient-to-r from-red-400 via-red-500 to-red-600 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-red-300 dark:focus:ring-red-800 font-medium rounded-lg text-sm px-5 py-1.5 text-center me-2 mb-2">
            Remove Store
          </button>
        </div>
      </div>

      <div class="w-full flex justify-center">
        <ul class="w-full md:w-96">
          <li v-for="(store, index) in currentPageStores" :key="index" class="flex items-center justify-between border-b py-0.5 px-2">
            <div class="flex flex-wrap">
              <input type="checkbox" v-model="selectedStores" :value="index" class="mr-2" />
              <img :src="getMarkerIcon(store.type)" class="w-5 mx-3" alt="#" @click="flyToStore(store)" />
              <div class="flex flex-col">
                <small class="font-semibold font-poppins">{{ store.name }}</small>
                <small class="font-extralight"> {{ store.type }}</small>
                <small class="font-extralight"> {{ store.city }}</small>
                <small class="font-extralight"> {{ store.address }}</small>
              </div>
            </div>
            <button @click="editStore(index)" class="text-white bg-gradient-to-r from-blue-500 via-blue-600 to-blue-700 hover:bg-gradient-to-br focus:ring-4 focus:outline-none focus:ring-blue-300 dark:focus:ring-blue-800 font-medium rounded-lg text-sm px-5 py-1.5 text-center me-2 mb-2">
              Edit
            </button>
          </li>
        </ul>
      </div>
    </div>

    <!-- Pagination -->
    <div class="flex justify-center mt-5">
      <button @click="prevPage" :disabled="currentPage === 1" class="hover:bg-gray-200 text-gray-800 font-semibold py-1 px-2 rounded">
        <small>Previous</small>
      </button>
      <span class="bg-white text-gray-800 font-bold py-2 px-4">
        {{ currentPage }}
      </span>
      <button @click="nextPage" :disabled="currentPage === totalPages" class="hover:bg-gray-200 text-gray-800 font-semibold py-1 px-2 rounded">
        <small>Next</small>
      </button>
    </div>
  </div>
  <hr
      class="my-6 border-gray-200 sm:mx-auto dark:border-gray-700 lg:my-8"
  />
  <span
      class="block text-sm text-gray-500 sm:text-center dark:text-gray-400"
  >© {{ new Date().getFullYear() }}
        <small><a href="#" class="hover:underline">Created by AG</a></small>
  </span>
</template>

<script>
import { defineComponent } from 'vue';
import axios from 'axios';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import 'leaflet-control-geocoder/dist/Control.Geocoder.css';
import 'leaflet-control-geocoder/dist/Control.Geocoder.js';

export default defineComponent({
  data() {
    return {
      storeName: '',
      city: '',
      address: '',
      stores: JSON.parse(localStorage.getItem('stores')) || [],
      storeType: '',
      selectedStores: [],
      map: null,
      geocoder: null,
      currentPage: 1,
      itemsPerPage: 5,
      showNotification: false,
      notificationMessage: '',
      notificationType: '',
      editIndex: null,
      mapKey: import.meta.env.VITE_MAP_API_KEY,
    };
  },
  computed: {
    totalPages() {
      return Math.ceil(this.stores.length / this.itemsPerPage);
    },
    currentPageStores() {
      const start = (this.currentPage - 1) * this.itemsPerPage;
      const end = start + this.itemsPerPage;
      return this.stores.slice(start, end);
    },
    notificationClass() {
      return {
        'bg-green-500': this.notificationType === 'add',
        'bg-red-500': this.notificationType === 'remove',
      };
    },
  },
  mounted() {
    this.initMap();
    this.loadStores();
    this.getCurrentLocation(); // Call method to get the current location
  },
  methods: {
    initMap() {
      this.map = L.map('map').setView([44.8226, 20.3911], 11);
      L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      }).addTo(this.map);

      this.geocoder = L.Control.Geocoder.nominatim();
    },
    async addStore() {
      if (this.editIndex !== null) {
        this.updateStore();
        return;
      }

      try {
        const response = await axios.get('https://www.mapquestapi.com/geocoding/v1/address', {
          params: {
            key: this.mapKey,
            location: `${this.address}, ${this.city}, ${this.storeType}, ${this.storeName}`,
          },
        });
        const location = response.data.results[0].locations[0].latLng;
        const store = {
          name: this.storeName,
          city: this.city,
          address: this.address,
          type: this.storeType,
          lat: location.lat,
          lng: location.lng,
        };
        this.stores.push(store);
        this.saveStores();
        this.addMarker(store);

        this.resetForm();

        this.showAddNotification('Store added successfully');
      } catch (error) {
        console.error('Geocoding error:', error);
        if (error.response && error.response.status === 401) {
          alert('Geocoding failed: Unauthorized. Please check your API key.');
        } else {
          alert('Geocoding failed: ' + error.message);
        }
      }
    },
    editStore(index) {
      const store = this.stores[index];
      this.storeName = store.name;
      this.city = store.city;
      this.address = store.address;
      this.storeType = store.type;
      this.editIndex = index;
    },
    updateStore() {
      const store = this.stores[this.editIndex];
      store.name = this.storeName;
      store.city = this.city;
      store.address = this.address;
      store.type = this.storeType;

      this.saveStores();
      this.loadStores();

      this.resetForm();

      this.showAddNotification('Store updated successfully');
      this.editIndex = null;
    },
    resetForm() {
      this.storeName = '';
      this.city = '';
      this.address = '';
      this.storeType = '';
    },
    addMarker(store) {
      const popupContent = `
        <b>${store.name}</b><br>
        ${store.type}<br>
        <b>City:</b> ${store.city}<br>
        <b>Address:</b> ${store.address}
      `;
      const iconUrl = this.getMarkerIcon(store.type);

      const svgIcon = L.icon({
        iconUrl,
        iconSize: [30, 30],
        iconAnchor: [15, 40],
        popupAnchor: [0, -35]
      });

      L.marker([store.lat, store.lng], { icon: svgIcon })
          .addTo(this.map)
          .bindPopup(popupContent)
          .openPopup();
    },
    getMarkerIcon(type) {
      switch (type) {
        case 'Electronics':
          return 'images/electronics-marker.svg';
        case 'Pharmacy':
          return 'images/pharmacy-marker.svg';
        case 'Restaurant':
          return 'images/restaurant-marker.svg';
        case 'Market':
          return 'images/shop-marker.svg';
        default:
          return 'images/home-marker.svg';
      }
    },
    saveStores() {
      localStorage.setItem('stores', JSON.stringify(this.stores));
    },
    loadStores() {
      this.stores.forEach(store => {
        if (store.lat && store.lng) {
          this.addMarker(store);
        }
      });
    },
    removeSelectedStores() {
      this.selectedStores.sort((a, b) => b - a);
      for (const index of this.selectedStores) {
        this.stores.splice(index, 1);
      }
      this.saveStores();
      this.map.eachLayer(layer => {
        if (layer instanceof L.Marker) {
          this.map.removeLayer(layer);
        }
      });
      this.loadStores();
      this.selectedStores = [];

      this.showRemoveNotification('Store removed successfully');
    },
    flyToStore(store) {
      if (store && store.lat && store.lng) {
        this.map.flyTo([store.lat, store.lng], 15);
      } else {
        console.error('Store location coordinates (lat/lng) are undefined.');
      }
    },
    prevPage() {
      if (this.currentPage > 1) {
        this.currentPage--;
      }
    },
    nextPage() {
      if (this.currentPage < this.totalPages) {
        this.currentPage++;
      }
    },
    showAddNotification(message) {
      this.notificationMessage = message;
      this.notificationType = 'add';
      this.showNotification = true;
      this.hideNotification();
    },
    showRemoveNotification(message) {
      this.notificationMessage = message;
      this.notificationType = 'remove';
      this.showNotification = true;
      this.hideNotification();
    },
    hideNotification() {
      setTimeout(() => {
        this.showNotification = false;
      }, 3000);
    },
    getCurrentLocation() {
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(this.handleGeolocationSuccess, this.handleGeolocationError);
      } else {
        console.error('Geolocation is not supported by this browser.');
      }
    },
    handleGeolocationSuccess(position) {
      const lat = position.coords.latitude;
      const lng = position.coords.longitude;
      this.map.setView([lat, lng], 11);
    },
    handleGeolocationError(error) {
      console.error('Error getting geolocation:', error);
      alert('Unable to retrieve your location.');
    }
  },
});
</script>



