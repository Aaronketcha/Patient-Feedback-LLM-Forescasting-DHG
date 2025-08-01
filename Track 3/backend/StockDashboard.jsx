import React, { useState, useEffect } from 'react';
import { Bar } from 'react-chartjs-2';
import axios from 'axios';
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend } from 'chart.js';

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

function StockDashboard() {
  const [stocks, setStocks] = useState([]);
  const [forecasts, setForecasts] = useState([]);
  const [bloodType, setBloodType] = useState('A+');

  useEffect(() => {
    axios.get(`http://localhost:8000/stocks/${bloodType}`)
      .then(response => setStocks(response.data))
      .catch(error => console.error('Erreur stocks:', error));
    axios.get(`http://localhost:8000/forecast/${bloodType}`)
      .then(response => setForecasts(response.data))
      .catch(error => console.error('Erreur prévisions:', error));
  }, [bloodType]);

  const getColor = (expiryDate) => {
    const today = new Date();
    const expiry = new Date(expiryDate);
    const daysLeft = (expiry - today) / (1000 * 60 * 60 * 24);
    if (daysLeft < 0) return 'red';
    if (daysLeft < 7) return 'yellow';
    return 'green';
  };

  const chartData = {
    labels: forecasts.map(f => f.forecast_date),
    datasets: [
      {
        label: `Stocks ${bloodType} (poches)`,
        data: stocks.map(s => Math.floor(s.collection_volume_ml / 450)),
        backgroundColor: stocks.map(s => getColor(s.expiry_date)),
      },
      {
        label: `Prévisions ${bloodType} (poches)`,
        data: forecasts.map(f => f.avg_forecast),
        backgroundColor: '#36A2EB',
        type: 'line'
      }
    ]
  };

  return (
    <div>
      <h2>Tableau de bord des stocks</h2>
      <select onChange={(e) => setBloodType(e.target.value)}>
        <option value="A+">A+</option>
        <option value="O+">O+</option>
        <option value="B+">B+</option>
        <option value="A-">A-</option>
        <option value="O-">O-</option>
        <option value="B-">B-</option>
        <option value="AB+">AB+</option>
        <option value="AB-">AB-</option>
      </select>
      <Bar data={chartData} options={{ responsive: true, plugins: { legend: { position: 'top' } } }} />
      <div>
        {stocks.map(s => (
          <div key={s.record_id} style={{ backgroundColor: getColor(s.expiry_date), padding: '5px', margin: '2px' }}>
            Poche {s.record_id}: {Math.floor(s.collection_volume_ml / 450)} poches, Expire: {s.expiry_date}
          </div>
        ))}
      </div>
    </div>
  );
}

export default StockDashboard;