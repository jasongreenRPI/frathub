import { useEffect, useState } from "react";

function App() {
  const [healthStatus, setHealthStatus] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    const checkHealth = async () => {
      try {
        const response = await fetch("http://localhost:8080/health");
        const data = await response.json();
        setHealthStatus(data.status);
      } catch (err) {
        setError("App is not healthy");
      }
    };

    checkHealth();
  }, []);

  return (
    <div>
      {error ? (
        <h4 style={{ color: "red" }}>{error}</h4>
      ) : (
        <h4>Health status: {healthStatus || "Loading..."}</h4>
      )}
    </div>
  );
}

export default App;
