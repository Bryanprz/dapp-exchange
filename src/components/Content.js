import React, { Component } from 'react'
import { connect } from 'react-redux'
import { loadAllOrders, subscribeToEvents } from '../store/interactions';
import { exchangeSelector, ordersSelector } from '../store/selectors';
import Trades from './Trades';
import OrderBook from './OrderBook';
import MyTransactions from './MyTransactions';
import PriceChart from './PriceChart';
import Balance from './Balance';
import NewOrder from './NewOrder';

class Content extends Component {
  componentWillMount() {
    // redux passes dispatch automatically as props 
    this.loadBlockchainData(this.props); 
  }

  async loadBlockchainData(props) {
    const { exchange, dispatch } = props
    await loadAllOrders(exchange, dispatch);
    await subscribeToEvents(exchange, dispatch)
  }

  render() {
    return (
      <div className="content">
        <div className="vertical-split">
          <Balance />
          <NewOrder />
        </div>
        <OrderBook />
        <div className="vertical-split">
          <PriceChart />
          <MyTransactions />
        </div>
        <Trades />
      </div>
    )
  }
}

// selectors have to be called from within this function because 
// selectors need state arg passed into them to retrieve correct piece of data
function mapStateToProps(state) {
  return {
    exchange: exchangeSelector(state),
    orders: ordersSelector(state)
  }
}

export default connect(mapStateToProps)(Content)

